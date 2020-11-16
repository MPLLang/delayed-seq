structure CLA = CommandLineArgs
structure Seq = ArraySequence

(* chosen by subdirectory *)
structure Grep = Grep

val pattern = CLA.parseString "pattern" ""
val filePath = CLA.parseString "infile" ""

val input =
  let
    val (source, tm) = Util.getTime (fn _ => ReadFile.contentsSeq filePath)
    val _ = print ("loadtime " ^ Time.fmt 4 tm ^ "s\n")
  in
    source
  end

val pattern =
  Seq.tabulate (fn i => String.sub (pattern, i)) (String.size pattern)

val n = Seq.length input
val _ = print ("n " ^ Int.toString n ^ "\n")

fun task () =
  Grep.grep pattern input

val result = Benchmark.run "running grep" task
val _ = print ("num matching lines " ^ Int.toString (Seq.length result) ^ "\n")

(* fun dumpLoop i =
  if i >= Seq.length result then () else
  let
    val (s, e) = Seq.nth result i
    val tok = CharVector.tabulate (e-s, fn k => Seq.nth input (s+k))
  in
    print tok;
    print "\n";
    dumpLoop (i+1)
  end

val _ = dumpLoop 0 *)
