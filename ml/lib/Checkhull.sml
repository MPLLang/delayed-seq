structure Checkhull:
sig

  type 'a seq = 'a ArraySequence.t

  datatype correctness =
    Correct
  | TooFewPoints
  | HyperExtensionAt of int
  | BadInteriorAngles of real
  | PointsOutside of int seq

  val check : (real * real) seq -> int seq -> correctness

  val report : (real * real) seq -> int seq -> correctness -> string

end =
struct

  structure Seq = ArraySequence
  structure DS = DelayedSeq

  fun delay s = DS.tabulate (Seq.nth s) (Seq.length s)

  structure G = Geometry2D

  type 'a seq = 'a Seq.t

  datatype correctness =
    Correct
  | TooFewPoints
  | HyperExtensionAt of int
  | BadInteriorAngles of real
  | PointsOutside of int seq

  fun checkDeduplicated pts hull =
    if Seq.length hull < 3 then TooFewPoints else
    let
      val n = Seq.length pts
      val m = Seq.length hull

      fun pt i = Seq.nth pts i
      fun hullpt i = pt (Seq.nth hull i)

      (* First: check convexity by adding up interior angles and
       * checking that they sum to pi(m-2). Also, check that there are no
       * hyperextensions: three points (p,q,r) along the hull that form
       * an angle larger than 180 degrees. *)

      fun hulltri i =
        ( hullpt (if i = 0 then m-1 else i-1)
        , hullpt i
        , hullpt (if i = m-1 then 0 else i+1)
        )

      val hyperExtendedIdx = ref (~1)
      val totalAngle =
        DS.reduce op+ 0.0 (DS.tabulate (fn i =>
          let
            val a = G.Point.triAngle (hulltri i)
          in
            if a < 0.0 then hyperExtendedIdx := i else ();
            a
          end
        ) m)

      val h = !hyperExtendedIdx
      val hasHyperExtension = !hyperExtendedIdx >= 0
      val correctAngleSum =
        Util.closeEnough (totalAngle, Math.pi * (Real.fromInt (m-2)))

      (* Next, find any points that lie outside the hull by filtering, for
       * each line segment of the hull, all points above that line *)

      fun hullseg i =
        (hullpt i, hullpt (if i = m-1 then 0 else i+1))

      fun aboveLine (p, q) i = G.Point.triArea (p, q, pt i) > 0.0

      val inHullFlags =
        DS.inject (DS.tabulate (fn _ => false) n,
                   DS.map (fn i => (i, true)) (delay hull))
      fun inHull i = DS.nth inHullFlags i

      fun outsideHull i =
        not (inHull i) andalso
        (DS.reduce (fn (a,b) => a orelse b) false
          (DS.tabulate (fn j => aboveLine (hullseg j) i) m))

      fun outsidePts () =
        DS.toArraySeq (DS.filter outsideHull (DS.tabulate (fn i => i) n))
    in

      if hasHyperExtension then
        HyperExtensionAt (!hyperExtendedIdx)
      else if not correctAngleSum then
        BadInteriorAngles totalAngle
      else
        let
          val outs = outsidePts ()
        in
          if Seq.length outs > 0 then
            PointsOutside outs
          else
            Correct
        end

    end

  fun check pts hull =
    let
      val hull' =
        DS.map (Seq.nth hull)
        (DS.filter
          (fn i => i = 0 orelse Seq.nth hull i <> Seq.nth hull (i-1))
          (DS.tabulate (fn i => i) (Seq.length hull)))
    in
      checkDeduplicated pts (DS.toArraySeq hull')
    end

  fun report pts hull correctness =
    let
      val n = Seq.length pts
      val m = Seq.length hull

      fun pt i = Seq.nth pts i
      fun hullpt i = pt (Seq.nth hull i)
    in
      case correctness of
        Correct => "yes"
      | TooFewPoints => "no! need at least 3 points"
      | HyperExtensionAt i =>
          let
            val (ai, bi, ci) =
              ( if i = 0 then m-1 else i-1
              , i
              , if i = m-1 then 0 else i+1
              )
            val (a, b, c) = (hullpt ai, hullpt bi, hullpt ci)
            val tos = G.Point.toString
          in
            "no! hyperextension at points " ^
            Int.toString ai ^ " " ^ Int.toString bi ^ " " ^ Int.toString ci ^ ": " ^
            tos a ^ " " ^ tos b ^ " " ^ tos c ^
            " form angle " ^
            Util.rtos (G.Point.triAngle (a, b, c))
          end
      | BadInteriorAngles totalAngle =>
          "no! interior angles sum to " ^ Util.rtos (totalAngle * 180.0 / Math.pi) ^
          " but should be " ^ Util.rtos (180.0 * Real.fromInt (Seq.length hull))
      | PointsOutside outs =>
          "no! " ^ Int.toString (Seq.length outs) ^ " points outside"
    end

end
