structure SeqBasis:
sig
  type grain = int

  val tabulate: grain -> (int * int) -> (int -> 'a) -> 'a array

  val foldl: ('b * 'a -> 'b)
          -> 'b
          -> (int * int)
          -> (int -> 'a)
          -> 'b

  val reduce: grain
           -> ('a * 'a -> 'a)
           -> 'a
           -> (int * int)
           -> (int -> 'a)
           -> 'a

  val scan: grain
         -> ('a * 'a -> 'a)
         -> 'a
         -> (int * int)
         -> (int -> 'a)
         -> 'a array  (* length N+1, for both inclusive and exclusive scan *)

  val filter: grain
           -> (int * int)
           -> (int -> 'a)
           -> (int -> bool)
           -> 'a array

  val tabFilter: grain
              -> (int * int)
              -> (int -> 'a option)
              -> 'a array
end =
struct

  type grain = int

  structure A = Array
  structure AS = ArraySlice

  (*
  fun upd a i x = Unsafe.Array.update (a, i, x)
  fun nth a i   = Unsafe.Array.sub (a, i)
  *)

  fun upd a i x = A.update (a, i, x)
  fun nth a i   = A.sub (a, i)

  val parfor = ForkJoin.parfor
  val par = ForkJoin.par
  val allocate = ForkJoin.alloc

  fun tabulate grain (lo, hi) f =
    let
      val n = hi-lo
      val result = allocate n
    in
      if lo = 0 then
        parfor grain (0, n) (fn i => upd result i (f i))
      else
        parfor grain (0, n) (fn i => upd result i (f (lo+i)));

      result
    end

  fun foldl g b (lo, hi) f =
    if lo >= hi then b else
    let
      val b' = g (b, f lo)
    in
      foldl g b' (lo+1, hi) f
    end

  fun reduce grain g b (lo, hi) f =
    if hi - lo <= grain then
      foldl g b (lo, hi) f
    else
      let
        val n = hi - lo
        val k = grain
        val m = 1 + (n-1) div k (* number of blocks *)

        fun red i j =
          case j - i of
            0 => b
          | 1 => foldl g b (lo + i*k, Int.min (lo + (i+1)*k, hi)) f
          | n => let val mid = i + (j-i) div 2
                 in g (par (fn _ => red i mid, fn _ => red mid j))
                 end
      in
        red 0 m
      end

  fun scan grain g b (lo, hi) (f : int -> 'a) =
    if hi - lo <= grain then
      let
        val n = hi - lo
        val result = allocate (n+1)
        fun bump ((j,b),x) = (upd result j b; (j+1, g (b, x)))
        val (_, total) = foldl bump (0, b) (lo, hi) f
      in
        upd result n total;
        result
      end
    else
      let
        val n = hi - lo
        val k = grain
        val m = 1 + (n-1) div k (* number of blocks *)
        val sums = tabulate 1 (0, m) (fn i =>
          let val start = lo + i*k
          in foldl g b (start, Int.min (start+k, hi)) f
          end)
        val partials = scan grain g b (0, m) (nth sums)
        val result = allocate (n+1)
      in
        parfor 1 (0, m) (fn i =>
          let
            fun bump ((j,b),x) = (upd result j b; (j+1, g (b, x)))
            val start = lo + i*k
          in
            foldl bump (i*k, nth partials i) (start, Int.min (start+k, hi)) f;
            ()
          end);
        upd result n (nth partials m);
        result
      end

  fun filter grain (lo, hi) f g =
    let
      val n = hi - lo
      val k = grain
      val m = 1 + (n-1) div k (* number of blocks *)
      fun count (i, j) c =
        if i >= j then c
        else if g i then count (i+1, j) (c+1)
        else count (i+1, j) c
      val counts = tabulate 1 (0, m) (fn i =>
        let val start = lo + i*k
        in count (start, Int.min (start+k, hi)) 0
        end)
      val offsets = scan grain op+ 0 (0, m) (nth counts)
      val result = allocate (nth offsets m)
      fun filterSeq (i, j) c =
        if i >= j then ()
        else if g i then (upd result c (f i); filterSeq (i+1, j) (c+1))
        else filterSeq (i+1, j) c
    in
      parfor 1 (0, m) (fn i =>
        let val start = lo + i*k
        in filterSeq (start, Int.min (start+k, hi)) (nth offsets i)
        end);
      result
    end

  fun tabFilter grain (lo, hi) (f : int -> 'a option) =
    let
      val n = hi - lo
      val k = grain
      val m = 1 + (n-1) div k (* number of blocks *)
      val tmp = allocate n

      fun filterSeq (i,j,k) =
        if (i >= j) then k
        else case f i of
           NONE => filterSeq(i+1, j, k)
         | SOME v => (A.update(tmp, k, v); filterSeq(i+1, j, k+1))

      val counts = tabulate 1 (0, m) (fn i =>
        let val last = filterSeq (lo + i*k, lo + Int.min((i+1)*k, n), i*k)
        in last - i*k
        end)

      val outOff = scan grain op+ 0 (0, m) (fn i => A.sub (counts, i))
      val outSize = A.sub (outOff, m)

      val result = allocate outSize
    in
      (* Choosing grain = n/outSize assumes that the blocks are all
       * approximately the same amount full. We could do something more
       * complex here, e.g. binary search to recursively split up the
       * range into small pieces of all the same size. *)
      parfor (n div (Int.max (outSize, 1))) (0, m) (fn i =>
        let
          val soff = i * k
          val doff = A.sub (outOff, i)
          val size = A.sub (outOff, i+1) - doff
        in
          Util.for (0, size) (fn j =>
            A.update (result, doff+j, A.sub (tmp, soff+j)))
        end);
      result
    end

  (** =====================================================================
    * pack/unpack
    * elements are stored starting at the lsb
    *)

(*
  fun pack8ElemsStartingAt i f =
    let
      open Word8
      infix 2 << orb
      val op+ = Int.+
      val (w, c) = (0w0: Word8.word, 0: int)
      val (w, c) = if f (i  ) then (w orb (0w1       ), c+1) else (w, c)
      val (w, c) = if f (i+1) then (w orb (0w1 << 0w1), c+1) else (w, c)
      val (w, c) = if f (i+2) then (w orb (0w1 << 0w2), c+1) else (w, c)
      val (w, c) = if f (i+3) then (w orb (0w1 << 0w3), c+1) else (w, c)
      val (w, c) = if f (i+4) then (w orb (0w1 << 0w4), c+1) else (w, c)
      val (w, c) = if f (i+5) then (w orb (0w1 << 0w5), c+1) else (w, c)
      val (w, c) = if f (i+6) then (w orb (0w1 << 0w6), c+1) else (w, c)
      val (w, c) = if f (i+7) then (w orb (0w1 << 0w7), c+1) else (w, c)
    in
      (w, c)
    end


  fun packAtMost8ElemsInRange (i, j) f =
    if i+8 > j then
      raise Fail "SeqBasis.packAtMost8ElemsInRange: more than 8 elems"
    else
      Util.loop (0, j-i) (0w0: Word8.word, 0: int) (fn ((w, c), k) =>
        if f (i+k) then
          (Word8.orb (w, Word8.<< (0w1, Word.fromInt k)), c+1)
        else
          (w, c)
      )


  fun iterate8Flags (w: Word8.word) (b: 'a) (f: bool * 'a -> 'a) =
    let
      open Word8
      infix 2 >> andb
      val b = f (0w1 = ((w       ) andb 0w1), b)
      val b = f (0w1 = ((w >> 0w1) andb 0w1), b)
      val b = f (0w1 = ((w >> 0w2) andb 0w1), b)
      val b = f (0w1 = ((w >> 0w3) andb 0w1), b)
      val b = f (0w1 = ((w >> 0w4) andb 0w1), b)
      val b = f (0w1 = ((w >> 0w5) andb 0w1), b)
      val b = f (0w1 = ((w >> 0w6) andb 0w1), b)
      val b = f (0w1 = ((w >> 0w7) andb 0w1), b)
    in
      b
    end


  fun iterateAtMost8ElemsInRange (w, count) b f =
    let
      open Word8
      infix 2 >> andb
      val op> = Int.>
    in
      if count > 8 then
        raise Fail "SeqBasis.iterateAtMost8ElemsInRange: more than 8 elems"
      else
        Util.loop (0, count) b (fn (b, k) =>
          f (0w1 = ((w >> Word.fromInt k) andb 0w1), b)
        )
    end


  fun writeFlagsFilter grain (lo, hi) (f: int -> 'a) (g: int -> bool) =
    let
      val n = hi - lo

      (** round up block size to multiple of 8 *)
      val blockSize = 8 * (Util.ceilDiv grain 8)
      val numBlocks = Util.ceilDiv n blockSize
      val numFlags = Util.ceilDiv n 8
      val packedFlags = allocate numFlags

      fun packFlagsForBlock b =
        let
          val start = lo + b * blockSize
          val stop = Int.min (start + blockSize, hi)

          fun loop count idx =
            if idx >= stop then
              count
            else if idx + 8 <= stop then
              let
                val (w, c) = pack8ElemsStartingAt idx g
              in
                upd packedFlags ((idx-lo) div 8) w;
                loop (count+c) (idx+8)
              end
            else
              let
                val (w, c) = packAtMost8ElemsInRange (idx, stop) g
              in
                upd packedFlags ((idx-lo) div 8) w;
                count+c
              end
        in
          loop 0 start
        end

      val blockCounts = tabulate 1 (0, numBlocks) packFlagsForBlock
      val offsets = scan grain op+ 0 (0, numBlocks) (nth blockCounts)
      val total = nth offsets numBlocks
      val output = allocate total

      fun outputBlock b =
        let
          val start = lo + b * blockSize
          val stop = Int.min (start + blockSize, hi)

          fun loop count idx =
            if idx >= stop then
              count
            else if idx + 8 <= stop then
              let
                val flags = nth packedFlags (idx div 8)
                val = iterate8Flags flags count (fn (flag, off) =>
                  if flag then
                    ( upd output
              in
              end
            else
              let
              in
              end

        in
        end
    in
    end
*)

end
