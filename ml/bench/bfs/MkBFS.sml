functor MkBFS (Seq: SEQUENCE) =
struct

  structure G = AdjacencyGraph(Int)

  fun bfs graph source =
    let
      val N = G.numVertices graph
      val M = G.numEdges graph

      val flags = ForkJoin.alloc N
      val _ = ForkJoin.parfor 10000 (0, N) (fn i =>
        Array.update (flags, i, 0w0: Word8.word))

      fun isVisited v =
        Array.sub (flags, v) = 0w1

      fun visit v =
        not (isVisited v) andalso
        (0w0 = Concurrency.casArray (flags, v) (0w0, 0w1))

      fun loop frontier totalVisited =
        if Seq.length frontier = 0 then totalVisited else
        let
          val allNeighbors = Seq.flatten (Seq.map (G.neighbors graph) frontier)
          val count = Seq.length allNeighbors
          val tmp = ForkJoin.alloc count
        in
          Seq.applyIdx allNeighbors (fn (i, u) =>
            if visit u then
              Array.update (tmp, i, u)
            else
              ???)
        end
    in
    end

end
