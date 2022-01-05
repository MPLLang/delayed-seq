structure NewDelayedSeq: SEQUENCE =
struct

  structure Stream = DelayedStream

  val for = Util.for
  val par = ForkJoin.par
  val parfor = ForkJoin.parfor
  val alloc = ForkJoin.alloc

  val gran = 5000
  val blockSize = 10000
  fun numBlocks n = Util.ceilDiv n blockSize

  structure A =
  struct
    open Array
    type 'a t = 'a array
    fun nth a i = sub (a, i)
  end

  structure AS =
  struct
    open ArraySlice
    type 'a t = 'a slice
    fun nth a i = sub (a, i)
  end


  type 'a rad = int * int * (int -> 'a)
  type 'a bid = int * (int -> 'a Stream.t)
  datatype 'a seq =
    Full of 'a AS.t
  | Rad of 'a rad
  | Bid of 'a bid

  type 'a t = 'a seq


  fun radlength (start, stop, _) = stop-start
  fun radnth (start, _, f) i = f (start+i)


  fun length s =
    case s of
      Full slice => AS.length slice
    | Rad rad => radlength rad
    | Bid (n, _) => n


  fun nth s i =
    case s of
      Full slice => AS.nth slice i
    | Rad rad => radnth rad i
    | Bid (n, getBlock) =>
        let
          val bidx = i div blockSize
        in
          Stream.nth (getBlock bidx) (i mod blockSize)
        end


  fun bidify (s: 'a seq) : 'a bid =
    let
      fun block start nth b =
        Stream.tabulate (fn i => nth (start + b*blockSize + i))
    in
      case s of
        Full slice =>
          let
            val (a, start, n) = AS.base slice
          in
            (n, block start (A.nth a))
          end

      | Rad (start, stop, nth) =>
          (stop-start, block start nth)

      | Bid xx => xx
    end


  fun applyIdx (s: 'a seq) (g: int * 'a -> unit) =
    let
      val (n, getBlock) = bidify s
    in
      parfor 1 (0, numBlocks n) (fn i =>
        let
          val lo = i*blockSize
          val hi = Int.min (lo+blockSize, n)
        in
          Stream.applyIdx (hi-lo, getBlock i) (fn (j, x) => g (lo+j, x))
        end)
    end


  fun apply (s: 'a seq) (g: 'a -> unit) =
    applyIdx s (fn (_, x) => g x)


  fun reify s =
    let
      val a = alloc (length s)
    in
      applyIdx s (fn (i, x) => A.update (a, i, x));
      AS.full a
    end


  fun force s = Full (reify s)


  fun radify s =
    case s of
      Full slice =>
        let
          val (a, i, n) = AS.base slice
        in
          (i, i+n, fn j => A.nth a (i+j))
        end

    | Rad xx => xx

    | Bid (n, blocks) =>
        radify (force s)


  fun tabulate f n =
    Rad (0, n, f)


  fun fromList xs =
    Full (AS.full (Array.fromList xs))


  fun % xs =
    fromList xs


  fun singleton x =
    Rad (0, 1, fn _ => x)


  fun $ x =
    singleton x


  fun empty () =
    fromList []


  fun fromArraySeq a =
    Full a


  fun range (i, j) =
    Rad (i, j, fn k => k)


  fun toArraySeq s =
    case s of
      Full x => x
    | _ => reify s


  fun map f s =
    case s of
      Full _ => map f (Rad (radify s))
    | Rad (i, j, g) => Rad (i, j, f o g)
    | Bid (n, getBlock) => Bid (n, Stream.map f o getBlock)


  fun mapIdx f s =
    case s of
      Full _ => mapIdx f (Rad (radify s))
    | Rad (i, j, g) => Rad (0, j-i, fn k => f (k, g (i+k)))
    | Bid (n, getBlock) =>
        Bid (n, fn b =>
          Stream.mapIdx (fn (i, x) => f (b*blockSize + i, x)) (getBlock b))


  fun enum s =
    mapIdx (fn (i,x) => (i,x)) s


  fun flatten (ss: 'a seq seq) : 'a seq =
    let
      val numChildren = length ss
      val children: 'a rad AS.t = reify (map radify ss)
      val offsets =
        SeqBasis.scan gran op+ 0 (0, numChildren) (radlength o AS.nth children)
      val totalLen = A.nth offsets numChildren
      fun offset i = A.nth offsets i

      val getBlock =
        Stream.makeBlockStreams
          { blockSize = blockSize
          , numChildren = numChildren
          , offset = offset
          , getElem = (fn i => fn j => radnth (AS.nth children i) j)
          }
    in
      Bid (totalLen, getBlock)
    end


  fun filter f (s: 'a seq) =
    let
      val (n, getBlock) = bidify s
      val packed: 'a rad array =
        SeqBasis.tabulate 1 (0, numBlocks n) (fn b =>
          let
            val lo = b*blockSize
            val hi = Int.min (lo+blockSize, n)
          in
            radify (Full (Stream.pack f (hi-lo, getBlock b)))
          end)
      val offsets =
        SeqBasis.scan gran op+ 0 (0, numBlocks n) (radlength o A.nth packed)
      val totalLen = A.nth offsets (numBlocks n)
      fun offset i = A.nth offsets i

      val getBlock =
        Stream.makeBlockStreams
          { blockSize = blockSize
          , numChildren = numBlocks n
          , offset = offset
          , getElem = (fn i =>
              let val child = A.nth packed i
              in radnth child
              end)
          }
    in
      Bid (totalLen, getBlock)
    end


  fun inject (s, u) =
    let
      val a = reify s
      val (base, i, _) = AS.base a
    in
      apply u (fn (j, x) => Array.update (base, i+j, x));
      Full a
    end


  (* ===================================================================== *)

  exception NYI
  exception Range
  exception Size

  datatype 'a listview = NIL | CONS of 'a * 'a seq
  datatype 'a treeview = EMPTY | ONE of 'a | PAIR of 'a seq * 'a seq

  type 'a ord = 'a * 'a -> order
  type 'a t = 'a seq

  fun append x = raise NYI
  fun filterIdx x = raise NYI

  fun iterate x = raise NYI
  fun iterateIdx x = raise NYI
  fun reduce x = raise NYI
  fun scan x = raise NYI
  fun scanIncl x = raise NYI
  fun mapOption x = raise NYI
  fun rev x = raise NYI
  fun subseq x = raise NYI
  fun toList x = raise NYI
  fun toString x = raise NYI
  fun zip x = raise NYI
  fun zipWith x = raise NYI


  fun argmax x = raise NYI
  fun collate x = raise NYI
  fun collect x = raise NYI
  fun drop x = raise NYI
  fun equal x = raise NYI
  fun iteratePrefixes x = raise NYI
  fun iteratePrefixesIncl x = raise NYI
  fun merge x = raise NYI
  fun sort x = raise NYI
  fun splitHead x = raise NYI
  fun splitMid x = raise NYI
  fun take x = raise NYI
  fun update x = raise NYI
  fun zipWith3 x = raise NYI

  fun filterSome x = raise NYI
  fun foreach x = raise NYI
  fun foreachG x = raise NYI

end
