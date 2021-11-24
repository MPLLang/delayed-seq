structure ArrayExtra =
struct
  open Array
  val alloc = arrayUninit
end

structure Word8ArrayExtra =
struct
  open Word8Array
  val alloc = arrayUninit
end
