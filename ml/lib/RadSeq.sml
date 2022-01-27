structure RadSeq =
struct

  open DelayedSeq
  val indexSearch = OffsetSearch.indexSearch

  fun flatten (ss: 'a seq seq): 'a seq =
    let
      val numChildren = length ss
      val children: 'a flat array = unravelAndCopy (map forceFlat ss)
      val offsets =
        SeqBasis.scan gran op+ 0 (0, numChildren) (flatLength o A.nth children)
      val total = A.nth offsets numChildren
      fun offset i = A.nth offsets i

      val result = alloc total
      val blockSize = 10000
      val numBlocks = Util.ceilDiv total blockSize
    in
      parfor 1 (0, numBlocks) (fn blockIdx =>
        let
          val lo = blockIdx * blockSize
          val hi = Int.min (lo + blockSize, total)

          val firstOuterIdx = indexSearch (0, numChildren, offset) lo
          val firstInnerIdx = lo - offset firstOuterIdx

          (** i = outer index
            * j = inner index
            * k = output index, ranges from [lo] to [hi]
            *)
          fun loop i j k =
            if k >= hi then () else
            let
              val inner = A.nth children i
              val numAvailableHere = flatLength inner - j
              val numRemainingInBlock = hi - k
              val numHere = Int.min (numAvailableHere, numRemainingInBlock)
            in
              for (0, numHere) (fn z => A.update (result, k+z, flatNth inner (j+z)));
              loop (i+1) 0 (k+numHere)
            end
        in
          loop firstOuterIdx firstInnerIdx lo
        end);

      Flat (Full (AS.full result))
    end


  fun scanDelay' g b (lo, hi, f) =
    let
      val n = hi-lo
      val nb = numBlocks n

      val blockSums =
        SeqBasis.tabulate 1 (0, nb) (fn blockIdx =>
          let
            val blockStart = lo + blockIdx*blockSize
            val blockEnd = Int.min (hi, blockStart + blockSize)
          in
            SeqBasis.foldl g b (blockStart, blockEnd) f
          end)

      val partials =
        SeqBasis.scan gran g b (0, nb) (A.nth blockSums)

      val result = alloc (n+1)
    in
      parfor 1 (0, nb) (fn i =>
        let
          val blockStart = i*blockSize
          val blockEnd = Int.min (n, blockStart + blockSize)
          val size = blockEnd-blockStart

          fun loop j b =
            if j >= size then ()
            else ( A.update (result, blockStart+j, b)
                 ; loop (j+1) (g (b, f (lo+blockStart+j)))
                 )
        in
          loop 0 (A.nth partials i)
        end);

      A.update (result, n, A.nth partials nb);
      ArraySlice.full result
    end


  fun scanDelay g b (s as (lo,hi,_)) =
    let
      (* val _ = print ("RadSeq.scanDelay...\n") *)
      val n = hi-lo
      val p = scanDelay' g b s
      val t = ArraySequence.nth p n
      val p = ArraySequence.subseq p (0, n)
      (* val _ = print ("RadSeq.scanDelay okay\n") *)
    in
      (Flat (Full p), t)
    end

  fun scanDelayIncl g b (s as (lo,hi,_)) =
    let
      (* val _ = print ("RadSeq.scanDelayIncl...\n") *)
      val n = hi-lo
      val p = scanDelay' g b s
      (* val _ = print ("RadSeq.scanDelay' okay\n") *)
      val p = ArraySequence.subseq p (1, n)
      (* val _ = print ("RadSeq.scanDelayIncl okay\n") *)
    in
      Flat (Full p)
    end

  fun scan (g: 'a * 'a -> 'a) (b: 'a) (s: 'a seq): ('a seq * 'a) =
    case s of
      Flat (Full slice) =>
        scanDelay g b (0, AS.length slice, AS.nth slice)
    | Flat (Delay (i, j, f)) =>
        scanDelay g b (i, j, f)
    | _ => scan g b (force s)

  fun scanIncl (g: 'a * 'a -> 'a) (b: 'a) (s: 'a seq): 'a seq =
    case s of
      Flat (Full slice) =>
        scanDelayIncl g b (0, AS.length slice, AS.nth slice)
    | Flat (Delay (i, j, f)) =>
        scanDelayIncl g b (i, j, f)
    | _ => scanIncl g b (force s)

end
