structure CLA = CommandLineArgs
structure Seq = ArraySequence

(* chosen by subdirectory *)
structure Tokens = Tokens

val n = CLA.parseInt "n" (1000 * 1000 * 100)
val filePath = CLA.parseString "infile" ""

fun gen i =
  if i mod 8 = 0 then #" " else #"a"

val input =
  if filePath = "" then
    Seq.tabulate gen n
  else
    let
      val (source, tm) = Util.getTime (fn _ => ReadFile.contentsSeq filePath)
      val _ = print ("loadtime " ^ Time.fmt 4 tm ^ "s\n")
    in
      source
    end

val n = Seq.length input
val _ = print ("n " ^ Int.toString n ^ "\n")

fun task () =
  Tokens.tokens Char.isSpace input

val result = Benchmark.run "tokens" task
val _ = print ("tokens " ^ Int.toString (Seq.length result) ^ "\n")

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
