structure CLA = CommandLineArgs
structure Seq = ArraySequence
structure G = AdjacencyGraph(Int)

(* Set by subdirectory *)
structure BFS = BFS

(* Generate an input
 * If -infile <file> is given, then will load file.
 * Otherwise, uses -n <num vertices> -d <degree> to generate a random graph. *)
val filename = CLA.parseString "infile" ""
val t0 = Time.now ()
val (graphspec, input) =
  if filename <> "" then
    (filename, G.parseFile filename)
  else
    let
      val n = CLA.parseOrDefaultInt "n" 1000000
      val d = CLA.parseOrDefaultInt "d" 10
    in
      ("random(" ^ Int.toString n ^ "," ^ Int.toString d ^ ")",
       G.randSymmGraph n d)
    end
val t1 = Time.now ()
val _ = print ("loaded graph in " ^ Time.fmt 4 (Time.- (t1, t0)) ^ "s\n")

val n = G.numVertices input
val source = CLA.parseInt "source" 0

val _ = print ("graph " ^ graphspec ^ "\n")
val _ = print ("num-verts " ^ Int.toString n ^ "\n")
val _ = print ("num-edges " ^ Int.toString (G.numEdges input) ^ "\n")
val _ = print ("source " ^ Int.toString source ^ "\n")

fun task () =
  BFS.bfs input source

val result = Benchmark.run "running bfs" task

val _ = print ("visited " ^ Int.toString result ^ "\n")
