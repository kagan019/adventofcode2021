using Base.Iterators

function parse_hexstring(hs :: String)
    map(hs |> collect) do ch
        fourbit = parse(Int,ch,base=16)
        [
            (fourbit >> 3) & 1,
            (fourbit >> 2) & 1,
            (fourbit >> 1) & 1,
            (fourbit >> 0) & 1
        ]
    end |> flatten
end

function input()
    sample_literal = "D2FE28"
    lit = read("day16/input.txt",String)
    parse_hexstring(lit) |> Iterators.Stateful
end

function bits_to_num(itr) :: BigInt
    i = BigInt(0)
    done = iterate(itr)
    while !isnothing(done)
        v,state = done
        i <<= 1
        i |= v
        done = iterate(itr,state)
    end
    i
end

struct Version
    val :: Int
    function Version(itr)
        b = take(itr,3) |> collect
        new(bits_to_num(b))
    end
end

struct TypeId
    val :: Int
    function TypeId(itr)
        b = take(itr,3) |> collect
        new(bits_to_num(b))
    end
end

abstract type Packet end

struct LiteralValue
    val :: Int
    function LiteralValue(itr)
        bitgroups = partition(itr,5)
        skipfirst = []
        followbit = peek(itr)
        @assert !isnothing(followbit)
        while followbit == 1
            push!(skipfirst, first(bitgroups)[2:end])
            followbit = peek(itr)
            @assert !isnothing(followbit)
        end
        push!(skipfirst, first(bitgroups)[2:end])
        new(skipfirst |> flatten |> bits_to_num)
    end
end

struct LiteralValuePacket <: Packet
    version :: Version
    tid :: TypeId
    val :: LiteralValue
    function LiteralValuePacket(v :: Version, t :: TypeId, itr)
        new(
            v,
            t,
            LiteralValue(itr)
        )
    end
end

struct LengthTypeId
    val :: Bool
    function LengthTypeId(itr)
        new(Bool(first(itr)))
    end
end

abstract type PacketArgSize end

struct SubPacketLength <: PacketArgSize
    len :: Int # the total length in bits of the next subpacket
    function SubPacketLength(itr)
        new(take(itr,15) |> bits_to_num)
    end
end

function argsize(spl :: SubPacketLength)
    spl.len
end

struct SubPacketCount <: PacketArgSize
    count :: Int # the number of subpackets contained
    function SubPacketCount(itr)
        new(take(itr,11) |> bits_to_num)
    end
end

function argsize(spc :: SubPacketCount)
    spc.count
end

function subpacket_argsize(ltid :: LengthTypeId, itr)
    if ltid.val
        SubPacketCount(itr)
    else
        SubPacketLength(itr)
    end
end

struct OperatorPacket <: Packet
    version :: Version
    tid :: TypeId
    length_tid :: LengthTypeId
    argsize :: PacketArgSize
    subpackets :: Vector{Packet}
    function OperatorPacket(v :: Version, t :: TypeId, itr)
        new(
            v,
            t,
            begin ltid = LengthTypeId(itr) end,
            begin asz = subpacket_argsize(ltid,itr) end,
            packets(asz, itr)
        )
    end
end

function Packet(itr)
    v = Version(itr)
    tid = TypeId(itr)
    if tid.val == 4
        LiteralValuePacket(v,tid,itr)
    else
        OperatorPacket(v,tid,itr)
    end
end

function packets(argsz :: SubPacketCount, itr)
    p = []
    for _=1:argsize(argsz)
        push!(p,Packet(itr))
    end
    p
end

function packets(argsz :: SubPacketLength, itr)
    bits = take(itr, argsize(argsz)) |> Iterators.Stateful
    p = []
    while !isempty(bits)
        push!(p,Packet(bits))
    end
    p
end

# part 1
sumversions(packet :: LiteralValuePacket) = packet.version.val
sumversions(packet :: OperatorPacket) = packet.version.val + 
    ((sumversions(p) for p=packet.subpackets) |> sum)

sumversions(Packet(input()))

# part 2
ops = Dict(
    0 => sum,
    1 => Base.Fix1(foldl,*),
    2 => Base.splat(min),
    3 => Base.splat(max),
    5 => Int ∘ Base.splat(>),
    6 => Int ∘ Base.splat(<),
    7 => Int ∘ Base.splat(==)
)
evalpacket(packet :: LiteralValuePacket) = packet.val.val
evalpacket(packet :: OperatorPacket) = packet.subpackets |> 
    Base.Fix1(map,evalpacket) |> 
    ops[packet.tid.val]

evalpacket(Packet(input()))
