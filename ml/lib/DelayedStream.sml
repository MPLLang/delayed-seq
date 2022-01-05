structure DelayedStream :>
sig
  type 'a t
  type 'a stream = 'a t

  val nth: 'a stream -> int -> 'a

  val tabulate: (int -> 'a) -> 'a stream
  val map: ('a -> 'b) -> 'a stream -> 'b stream
  val mapIdx: (int * 'a -> 'b) -> 'a stream -> 'b stream
  val zipWith: ('a * 'b -> 'c) -> 'a stream * 'b stream -> 'c stream
  val iteratePrefixes: ('b * 'a -> 'b) -> 'b -> 'a stream -> 'b stream
  val iteratePrefixesIncl: ('b * 'a -> 'b) -> 'b -> 'a stream -> 'b stream

  val applyIdx: int * 'a stream -> (int * 'a -> unit) -> unit
  val iterate: ('b * 'a -> 'b) -> 'b -> int * 'a stream -> 'b

  val pack: ('a -> bool) -> (int * 'a stream) -> 'a ArraySlice.slice

  val makeBlockStreams:
    { blockSize: int
    , numChildren: int
    , offset: int -> int
    , getElem: int -> int -> 'a
    }
    -> (int -> 'a stream)

  (** `indexSearch (start, stop, offsetFn) k` returns which inner sequence
    * contains index `k`. The tuple arg defines a sequence of offsets.
    *)
  val indexSearch: int * int * (int -> int) -> int -> int

end =
struct

  (* Using given offsets, find which inner sequence contains index [k] *)
  fun indexSearch (start, stop, offset: int -> int) k =
    case stop-start of
      0 =>
        raise Fail "DelayedStream.indexSearch: should not have hit 0"
    | 1 =>
        start
    | n =>
        let
          val mid = start + (n div 2)
        in
          if k < offset mid then
            indexSearch (start, mid, offset) k
          else
            indexSearch (mid, stop, offset) k
        end

  (** A stream is a generator for a stateful trickle function:
    *   trickle = stream ()
    *   x0 = trickle 0
    *   x1 = trickle 1
    *   x2 = trickle 2
    *   ...
    *
    *  The integer argument is just an optimization (it could be packaged
    *  up into the state of the trickle function, but doing it this
    *  way is more efficient). Requires passing `i` on the ith call
    *  to trickle.
    *)
  type 'a t = unit -> int -> 'a
  type 'a stream = 'a t


  fun nth stream i =
    let
      val trickle = stream ()

      fun loop j =
        let
          val x = trickle j
        in
          if j = i then x else loop (j+1)
        end
    in
      loop 0
    end


  fun tabulate f =
    fn () => f


  fun map g stream =
    fn () =>
      let
        val trickle = stream ()
      in
        g o trickle
      end


  fun mapIdx g stream =
    fn () =>
      let
        val trickle = stream ()
      in
        fn idx => g (idx, trickle idx)
      end


  fun applyIdx (length, stream) g =
    let
      val trickle = stream ()
      fun loop i =
        if i >= length then () else (g (i, trickle i); loop (i+1))
    in
      loop 0
    end


  fun resize arr =
    let
      val newCapacity = 2 * Array.length arr
      val dst = ForkJoin.alloc newCapacity
    in
      Array.copy {src = arr, dst = dst, di = 0};
      dst
    end


  fun pack pred (length, stream) =
    let
      val trickle = stream ()

      fun loop (data, next) i =
        if i >= length then
          (data, next)
        else if next >= Array.length data then
          loop (resize data, next) i
        else
          let
            val x = trickle i
          in
            if pred x then
              ( Array.update (data, next, x)
              ; loop (data, next+1) (i+1)
              )
            else
              loop (data, next) (i+1)
          end

      val (data, count) = loop (ForkJoin.alloc 100, 0) 0
    in
      ArraySlice.slice (data, 0, SOME count)
    end


  fun iterate g b (length, stream) =
    let
      val trickle = stream ()
      fun loop b i =
        if i >= length then b else loop (g (b, trickle i)) (i+1)
    in
      loop b 0
    end


  fun iteratePrefixes g b stream =
    fn () =>
      let
        val trickle = stream ()
        val stuff = ref b
      in
        fn idx =>
          let
            val acc = !stuff
            val elem = trickle idx
            val acc' = g (acc, elem)
          in
            stuff := acc';
            acc
          end
      end


  fun iteratePrefixesIncl g b stream =
    fn () =>
      let
        val trickle = stream ()
        val stuff = ref b
      in
        fn idx =>
          let
            val acc = !stuff
            val elem = trickle idx
            val acc' = g (acc, elem)
          in
            stuff := acc';
            acc'
          end
      end


  fun zipWith g (s1, s2) =
    fn () =>
      let
        val trickle1 = s1 ()
        val trickle2 = s2 ()
      in
        fn idx => g (trickle1 idx, trickle2 idx)
      end


  fun makeBlockStreams
        { blockSize: int
        , numChildren: int
        , offset: int -> int
        , getElem: int -> int -> 'a
        } =
    let
      fun getBlock blockIdx =
        let
          val lo = blockIdx * blockSize
          val firstOuterIdx = indexSearch (0, numChildren, offset) lo
          (* val firstInnerIdx = lo - offset firstOuterIdx *)

          fun advanceUntilNonEmpty i =
            if i >= numChildren orelse offset i <> offset (i+1) then
              i
            else
              advanceUntilNonEmpty (i+1)
        in
          fn () =>
            let
              val outerIdx = ref firstOuterIdx
              (* val innerIdx = ref firstInnerIdx *)
            in
              fn idx =>
                let
                  val i = !outerIdx
                  val j = lo + idx - offset i
                  (* val j = !innerIdx *)
                  val elem = getElem i j
                in
                  if offset i + j + 1 < offset (i+1) then
                    (* innerIdx := j+1 *) ()
                  else
                    ( outerIdx := advanceUntilNonEmpty (i+1)
                    (* ; innerIdx := 0 *)
                    );

                  elem
                end
            end
        end

    in
      getBlock
    end


end
