module SIUnits

    immutable SIQuantity{T<:Number,m,kg,s,A,K,mol,cd} <: Number
        val::T
    end

    typealias UnitQuantity{T} SIQuantity{T,0,0,0,0,0,0,0}

    SIQuantity{T<:Number}(x::T) = UnitQuantity{T}(x)

    immutable SIUnit{m,kg,s,A,K,mol,cd} <: Number
    end 

    abstract SIRanges{T<:Real,m,kg,s,A,K,mol,cd} <: Ranges{T}

    immutable SIRange{T<:Real,m,kg,s,A,K,mol,cd} <: SIRanges{T,m,kg,s,A,K,mol,cd}
        val::Range{T}
    end

    immutable SIRange1{T<:Real,m,kg,s,A,K,mol,cd} <: SIRanges{T,m,kg,s,A,K,mol,cd}
        val::Range1{T}
    end

    unit{T,m,kg,s,A,K,mol,cd}(x::SIRanges{T,m,kg,s,A,K,mol,cd}) = SIUnit{m,kg,s,A,K,mol,cd}()
    quantity{T,m,kg,s,A,K,mol,cd}(x::SIRanges{T,m,kg,s,A,K,mol,cd}) = SIQuantity{T,m,kg,s,A,K,mol,cd}

    import Base: length, getindex, next, float64, float, int, show, start, step, last, done, first, eltype

    # This is all nessecary because SIQuanity{T<:Real} !<: Real
    show(io::IO, x::SIRanges) = (show(io, x.val); show(io,unit(x)))
    function show(io::IO, r::SIRange)
        if step(r) == zero(quantity(r))
            print(io, "SIRange(",start(r),",",step(r),",",length(r),")")
        else
            print(io, start(r),':',step(r),':',last(r))
        end
    end
    show(io::IO, r::SIRange1) = print(io, first(r),':',last(r))
    getindex(r::SIRanges,i::Integer) = (quantity(r)(getindex(x.val,i)))
    function next(r::SIRanges, i) 
        v, j = next(r.val,i)
        to_q(quantity(r),v), j
    end
    length(r::SIRanges) = length(r.val)
    start(r::SIRanges) = start(r.val)
    done(r::SIRanges,i) = done(r.val,i)
    eltype(r::SIRanges) = quantity(r)

    for func in (:first,:step,:last)
        @eval $(func)(r::SIRanges) = to_q(quantity(r),$(func)(r.val))
    end

    typealias UnitTuple NTuple{7,Int64}

    tup2u(tup) = SIUnit{tup[1],tup[2],tup[3],tup[4],tup[5],tup[6],tup[7]}
    quantity(T::Type,tup::UnitTuple) = quantity(T,tup2u(tup)())
    -(tup::UnitTuple) = (-tup[1],-tup[2],-tup[3],-tup[4],-tup[5],-tup[6],-tup[7])

    for op in (:-,:*,:+)
        @eval function $(op)(tup1::UnitTuple,tup2::UnitTuple)
            ($(op)(tup1[1],tup2[1]),$(op)(tup1[2],tup2[2]),$(op)(tup1[3],tup2[3]),$(op)(tup1[4],tup2[4]),$(op)(tup1[5],tup2[5]),
                $(op)(tup1[6],tup2[6]),$(op)(tup1[7],tup2[7]))
        end
    end

    import Base: +, -, *, /, //, ^, promote_rule, convert, show, ==, mod

    export quantity, @quantity

    function quantity{S}(T,quant::SIQuantity{S}) 
        quant.val == one(S) || error("Quantity value must be unity!")
        quantity(T,unit(quant))
    end
    quantity{m,kg,s,A,K,mol,cd}(T::Union(Type,TypeVar),unit::SIUnit{m,kg,s,A,K,mol,cd}) = SIQuantity{T,m,kg,s,A,K,mol,cd}

    tup{m,kg,s,A,K,mol,cd}(u::SIUnit{m,kg,s,A,K,mol,cd}) = (m,kg,s,A,K,mol,cd)
    tup{T,m,kg,s,A,K,mol,cd}(u::SIQuantity{T,m,kg,s,A,K,mol,cd}) = (m,kg,s,A,K,mol,cd)

    macro quantity(expr,unit)
        esc(:(SIUnits.SIQuantity{$expr,SIUnits.tup($unit)...}))
    end

    # MathConsts propagate through units. Fancy!!
    promote_rule{sym,m,kg,s,A,K,mol,cd}(x::Type{MathConst{sym}},y::Type{SIUnit{m,kg,s,A,K,mol,cd}}) = 
        SIQuantity{MathConst{sym},m,kg,s,A,K,mol,cd}
    promote_rule{sym,T,m,kg,s,A,K,mol,cd}(x::Type{MathConst{sym}},y::Type{SIQuantity{T,m,kg,s,A,K,mol,cd}}) = 
        SIQuantity{promote_type(MathConst{sym},T)}

    promote_rule{T,S,mS,kgS,sS,AS,KS,molS,cdS,mT,kgT,sT,AT,KT,molT,cdT}(
        A::Type{SIQuantity{T,mT,kgT,sT,AT,KT,molT,cdT}},B::Type{SIQuantity{S,mS,kgS,sS,AS,KS,molS,cdS}}) = SIQuantity{promote_type(T,S)}
    promote_rule{T,mS,kgS,sS,AS,KS,molS,cdS,mT,kgT,sT,AT,KT,molT,cdT}(
        A::Type{SIQuantity{T,mT,kgT,sT,AT,KT,molT,cdT}},B::Type{SIUnit{mS,kgS,sS,AS,KS,molS,cdS}}) = SIQuantity{T}
    promote_rule{S,m,kg,s,A,K,mol,cd}(x::Type{Bool},y::Type{SIQuantity{S,m,kg,s,A,K,mol,cd}}) = SIQuantity{promote_type(Bool,S)}
    promote_rule{m,kg,s,A,K,mol,cd}(x::Type{Bool},y::Type{SIUnit{m,kg,s,A,K,mol,cd}}) = SIQuantity{Bool}
    promote_rule{T,S,m,kg,s,A,K,mol,cd}(x::Type{T},y::Type{SIQuantity{S,m,kg,s,A,K,mol,cd}}) = SIQuantity{promote_type(T,S)}
    promote_rule{T,m,kg,s,A,K,mol,cd}(x::Type{T},y::Type{SIUnit{m,kg,s,A,K,mol,cd}}) = SIQuantity{T}

    # One unspecified, units, one concrete (unspecified occurs as the promotion result from the rules above)
    promote_rule{T,S,m,kg,s,A,K,mol,cd}(x::Type{SIQuantity{T}},y::Type{SIQuantity{S,m,kg,s,A,K,mol,cd}}) = SIQuantity{promote_type(T,S)}

    convert{T,m,kg,s,A,K,mol,cd}(::Type{SIQuantity{T}},x::SIUnit{m,kg,s,A,K,mol,cd}) = SIQuantity{T,m,kg,s,A,K,mol,cd}(one(T))
    convert{T}(::Type{SIQuantity{T}},x::T) = UnitQuantity{T}(x)
    convert{T,S}(::Type{SIQuantity{T}},x::S) = convert(SIQuantity{T},convert(T,x))
    convert{T}(::Type{SIQuantity{T}},x::SIQuantity{T}) = x
    convert{T,S,m,kg,s,A,K,mol,cd}(::Type{SIQuantity{T}},x::SIQuantity{S,m,kg,s,A,K,mol,cd}) = SIQuantity{T,m,kg,s,A,K,mol,cd}(convert(T,x.val))

    to_q{T,m,kg,s,A,K,mol,cd}(::Type{SIQuantity{T,m,kg,s,A,K,mol,cd}},val::T) = (0 == m == kg == s == A == K == mol == cd) ? val : SIQuantity{T,m,kg,s,A,K,mol,cd}(val)
    convert{T,S,m,kg,s,A,K,mol,cd}(::Type{SIQuantity{T,m,kg,s,A,K,mol,cd}},val::S) = (SIQuantity{T,m,kg,s,A,K,mol,cd}(convert(T,val)))
    function convert{T,S,mS,kgS,sS,AS,KS,molS,cdS,mT,kgT,sT,AT,KT,molT,cdT}(::Type{SIQuantity{T,mT,kgT,sT,AT,KT,molT,cdT}},val::SIQuantity{S,mS,kgS,sS,AS,KS,molS,cdS})
        if mS != mT || kgS != kgT || sS != sT || AS != AT || KS != KT || molS != molT || cdS != cdT
            error("Dimension mismatch in convert. Attempted to convert a ($(repr(SIUnit{mS,kgS,sS,AS,KS,molS,cdS}))) to ($(repr(SIUnit{mT,kgT,sT,AT,KT,molT,cdT})))")
        end
        SIQuantity{T,mT,kgT,sT,AT,KT,molT,cdT}(convert(T,val.val))
    end

    for op in (:/,://)

        @eval function ($op){T}(x::Number,y::SIQuantity{T})
            val = ($op)(x,y.val)
            to_q(quantity(typeof(val),-tup(y)),val)
        end

        @eval function ($op)(x::SIQuantity,y::SIQuantity)
            val = $(op)(x.val,y.val)
            to_q(quantity(typeof(val),tup(x)-tup(y)),val)
        end

        @eval $(op)(x::SIUnit,y::SIUnit) = tup2u(tup(x)-tup(y))()
        @eval $(op){T}(x::SIQuantity{T},y::SIUnit) = to_q(quantity(T,tup(unit(x))-tup(y)),x.val)
        @eval $(op){T}(x::SIUnit,y::SIQuantity{T}) = to_q(quantity(T,tup(x)-tup(unit(y))),($op)(1,y.val))

        @eval $(op)(x::Number,y::SIUnit) = x*tup2u(-tup(y))()
    end

    inv(y::SIUnit) = tup2u(-tup(y))()

    function +{T,S,m,kg,s,A,K,mol,cd}(
        x::SIQuantity{T,m,kg,s,A,K,mol,cd},y::SIQuantity{S,m,kg,s,A,K,mol,cd})
        val = x.val+y.val
        SIQuantity{typeof(val),m,kg,s,A,K,mol,cd}(val)
    end

    function -{T,S,m,kg,s,A,K,mol,cd}(
        x::SIQuantity{T,m,kg,s,A,K,mol,cd},y::SIQuantity{S,m,kg,s,A,K,mol,cd}) 
        val = x.val-y.val
        SIQuantity{typeof(val),m,kg,s,A,K,mol,cd}(val)
    end

    function -{T,S,mS,kgS,sS,AS,KS,molS,cdS,mT,kgT,sT,AT,KT,molT,cdT}(
        x::SIQuantity{T,mT,kgT,sT,AT,KT,molT,cdT},y::SIQuantity{S,mS,kgS,sS,AS,KS,molS,cdS}) 
        error("Unit mismatch. Got ($(repr(unit(x)))) - ($(repr(unit(y))))")
    end     

    function +{T,S,mS,kgS,sS,AS,KS,molS,cdS,mT,kgT,sT,AT,KT,molT,cdT}(
        x::SIQuantity{T,mT,kgT,sT,AT,KT,molT,cdT},y::SIQuantity{S,mS,kgS,sS,AS,KS,molS,cdS}) 
        error("Unit mismatch. Got ($(repr(unit(x)))) + ($(repr(unit(y))))")
    end

    function -{T,m,kg,s,A,K,mol,cd}(x::SIQuantity{T,m,kg,s,A,K,mol,cd})
        val = -(x.val)
        SIQuantity{typeof(val),m,kg,s,A,K,mol,cd}(val)
    end

    function ^{T,m,kg,s,A,K,mol,cd}(
        x::SIQuantity{T,m,kg,s,A,K,mol,cd},i::Integer) 
        if i == 0
            return one(T)
        end
        val = x.val^i
        SIQuantity{typeof(val),m*i,kg*i,s*i,A*i,K*i,mol*i,cd*i}(val)
    end


    function ^{T,m,kg,s,A,K,mol,cd}(
        x::SIQuantity{T,m,kg,s,A,K,mol,cd},r::Rational) 
        if r == 0
            return one(T)
        end
        val = x.val^r
        SIQuantity{typeof(val),convert(Int,m*r),convert(Int,kg*r),convert(Int,s*r),convert(Int,A*r),
        convert(Int,K*r),convert(Int,mol*r),convert(Int,cd*r)}(val)
    end

    ^{T,m,kg,s,A,K,mol,cd}(x::SIQuantity{T,m,kg,s,A,K,mol,cd},r::FloatingPoint) = x^rationalize(r)

    ==(x::SIQuantity,y::SIQuantity) = (tup(x) == tup(y)) && (x.val == y.val)
    =={T}(x::SIQuantity{T},y::SIUnit) = (tup(x) == tup(y)) && (x.val == one(T))
    =={T}(x::SIUnit,y::SIQuantity{T}) = (tup(x) == tup(y)) && (one(T) == y.val)

    import Base: sqrt, abs, colon, isless, isfinite, isreal

    function colon{T,S,X,m,kg,s,A,K,mol,cd}(start::SIQuantity{T,m,kg,s,A,K,mol,cd},step::SIQuantity{S,m,kg,s,A,K,mol,cd},stop::SIQuantity{X,m,kg,s,A,K,mol,cd})
        val = colon(start.val,step.val,stop.val)
        SIRange{eltype(val),m,kg,s,A,K,mol,cd}(val)
    end

    function colon{T,S,m,kg,s,A,K,mol,cd}(start::SIQuantity{T,m,kg,s,A,K,mol,cd},stop::SIQuantity{S,m,kg,s,A,K,mol,cd})
        val = colon(start.val,stop.val)
        SIRange1{eltype(val),m,kg,s,A,K,mol,cd}(val)
    end

    function sqrt{T,m,kg,s,A,K,mol,cd}(x::SIQuantity{T,m,kg,s,A,K,mol,cd})
        val = sqrt(x.val)
        SIQuantity{typeof(val),convert(Int,m/2),convert(Int,kg/2),convert(Int,s/2),convert(Int,A/2),
        convert(Int,K/2),convert(Int,mol/2),convert(Int,cd/2)}(val)   
    end

    function abs{T,m,kg,s,A,K,mol,cd}(x::SIQuantity{T,m,kg,s,A,K,mol,cd})
        SIQuantity{T,m,kg,s,A,K,mol,cd}(abs(x.val))
    end

    function isfinite{T,m,kg,s,A,K,mol,cd}(x::SIQuantity{T,m,kg,s,A,K,mol,cd})
        isfinite(x.val)
    end

    isreal(x::SIQuantity) = isreal(x.val)

    function isless{T,S,mS,kgS,sS,AS,KS,molS,cdS,mT,kgT,sT,AT,KT,molT,cdT}(
        x::SIQuantity{T,mT,kgT,sT,AT,KT,molT,cdT},y::SIQuantity{S,mS,kgS,sS,AS,KS,molS,cdS}) 
        return isless(x.val,y.val)
    end

    function mod{T,S,mS,kgS,sS,AS,KS,molS,cdS,mT,kgT,sT,AT,KT,molT,cdT}(
        x::SIQuantity{T,mT,kgT,sT,AT,KT,molT,cdT},y::SIQuantity{S,mS,kgS,sS,AS,KS,molS,cdS}) 
        error("Unit mismatch. Got mod($(repr(unit(x))),$(repr(unit(y))))")
    end
    
    function mod{T,S,m,kg,s,A,K,mol,cd}(x::SIQuantity{T,m,kg,s,A,K,mol,cd},y::SIQuantity{S,m,kg,s,A,K,mol,cd})
        val = mod(x.val,y.val)
        SIQuantity{typeof(val),m,kg,s,A,K,mol,cd}(val)
    end

    # Forwarding methods that do not affect units
    import Base: conj
    conj(x::SIQuantity) = typeof(x)(conj(x.val))

    float64(x::SIQuantity) = float64(x.val)
    float(x::SIQuantity) = float(x.val)
    int(x::SIQuantity) = int(x.val)

    *(x::SIUnit,y::SIUnit) = tup2u(tup(x)+tup(y))()
    *{T}(x::SIUnit,y::SIQuantity{T}) = to_q(quantity(T,tup(y)+tup(x)),y.val)
    *{T}(x::SIQuantity{T},y::SIUnit) = to_q(quantity(T,tup(y)+tup(x)),x.val)
    *(x::MathConst,y::SIUnit) = quantity(typeof(x),y)(x)
    function *(x::SIQuantity,y::SIQuantity) 
        ret = x.val * y.val
        to_q(quantity(typeof(ret),tup(x)+tup(y)),ret)
    end


    function ^{m,kg,s,A,K,mol,cd}(
        x::SIUnit{m,kg,s,A,K,mol,cd},i::Integer) 
        SIUnit{m*i,kg*i,s*i,A*i,K*i,mol*i,cd*i}()
    end

    unit{T,m,kg,s,A,K,mol,cd}(x::SIQuantity{T,m,kg,s,A,K,mol,cd}) = SIUnit{m,kg,s,A,K,mol,cd}()

    export SIPrefix, Meter, KiloGram, Second, Ampere, Kelvin, Mole, Candela, Kilo, Mega, Giga,
        Tera, Peta, Exa, Zetta, Centi, Milli, Micro, Nano, Pico, Femto, Atto, Zepto, Yocto,
        Gram, Joule, Coulomb, Volt, Farad, Newton, Ohm, CentiMeter, Siemens, Hertz, Watt, Pascal

    const SIPrefix = SIUnit{0,0,0,0,0,0,0}()
    const Meter    = SIUnit{1,0,0,0,0,0,0}()
    const KiloGram = SIUnit{0,1,0,0,0,0,0}()
    const Second   = SIUnit{0,0,1,0,0,0,0}()
    const Ampere   = SIUnit{0,0,0,1,0,0,0}()
    const Kelvin   = SIUnit{0,0,0,0,1,0,0}()
    const Mole     = SIUnit{0,0,0,0,0,1,0}()
    const Candela  = SIUnit{0,0,0,0,0,0,1}()

    const Kilo       = (1000)SIPrefix
    const Mega       = (10^6)SIPrefix
    const Giga       = (10^9)SIPrefix
    const Tera       = (10^12)SIPrefix
    const Peta       = (10^15)SIPrefix
    const Exa        = (10^18)SIPrefix
    const Zetta      = (10^21)SIPrefix
    const Yotta      = (10^24)SIPrefix
    const Centi      = (1//100)SIPrefix
    const Milli      = (1//1000)SIPrefix
    const Micro      = (1//10^6)SIPrefix
    const Nano       = (1//10^9)SIPrefix
    const Pico       = (1//10^12)SIPrefix
    const Femto      = (1//10^15)SIPrefix
    const Atto       = (1//10^18)SIPrefix
    const Zepto      = (1//10^21)SIPrefix
    const Yocto      = (1//10^24)SIPrefix

    const Gram       = (1//1000)KiloGram
    const Joule      = KiloGram*Meter^2/Second^2
    const Coulomb    = Ampere*Second
    const Volt       = Joule/Coulomb
    const Farad      = Coulomb^2/Joule
    const Newton     = KiloGram*Meter/Second^2
    const Ohm        = Volt/Ampere
    const Hertz      = inv(Second)
    const Siemens    = inv(Ohm)
    const Watt       = Joule/Second
    const Pascal     = Newton/Meter^2

    const CentiMeter = Centi*Meter


# Pretty Printing - Text 
    superscript(i) = map(repr(i)) do c
        c   ==  '-' ? '\u207b' :
        c   ==  '1' ? '\u00b9' :
        c   ==  '2' ? '\u00b2' :
        c   ==  '3' ? '\u00b3' :
        c   ==  '4' ? '\u2074' :
        c   ==  '5' ? '\u2075' :
        c   ==  '6' ? '\u2076' :
        c   ==  '7' ? '\u2077' :
        c   ==  '8' ? '\u2078' :
        c   ==  '9' ? '\u2079' :
        c   ==  '0' ? '\u2070' :
        error("Unexpected Chatacter")
    end

    function show{m,kg,s,A,K,mol,cd}(io::IO,x::SIUnit{m,kg,s,A,K,mol,cd})
        kg != 0 && print(io,"kg",(kg == 1 ? " " :superscript(kg)))
        m != 0 && print(io,"m",(m == 1 ? " " : superscript(m)))
        s != 0 && print(io,"s",(s == 1 ? " " :superscript(s)))
        A != 0 && print(io,"A",(A == 1 ? " " :superscript(A)))
        K != 0 && print(io,"K",(K == 1 ? " " :superscript(K)))
        mol != 0 && print(io,"mol",(mol == 1 ? " " :superscript(mol)))
        cd != 0 && print(io,"cd",(cd == 1 ? " " :uperscript(cd)))
    end

    function show{T,m,kg,s,A,K,mol,cd}(io::IO,x::SIQuantity{T,m,kg,s,A,K,mol,cd})
        show(io,x.val)
        print(io," ")
        show(io,unit(x))
    end

    function sidims{m,kg,s,A,K,mol,cd}(::SIUnit{m,kg,s,A,K,mol,cd})
        (m,kg,s,A,K,mol,cd)
    end

    function sidims{T,m,kg,s,A,K,mol,cd}(::SIQuantity{T,m,kg,s,A,K,mol,cd})
        (m,kg,s,A,K,mol,cd)
    end

    export @prettyshow

    macro prettyshow(unit,string)
        esc(quote function Base.show(io::IO,::SIUnits.SIUnit{SIUnits.sidims($(unit))...})
            print(io,$(string))
        end
        function Base.Multimedia.writemime(io::IO,::MIME"text/mathtex+latex",::SIUnits.SIUnit{SIUnits.sidims($(unit))...})
            Base.Multimedia.writemime(io,MIME("text/mathtex+latex"),$(string))
        end
        end) 
    end

# Pretty Printing - LaTeX

    using TexExtensions

    import Base: writemime

    macro l(x)
        esc(quote
            $x != 0 && push!($x>0?num:den,string("\\text{",$(string(x)),"\}",abs($x) == 1 ? " " : string("^{",abs($x),"}")))
        end)
    end

    function Base.Multimedia.writemime{m,kg,s,A,K,mol,cd}(io::IO,::MIME"text/mathtex+latex",x::SIUnit{m,kg,s,A,K,mol,cd})
        num = ASCIIString[]
        den = ASCIIString[]
        @l kg
        @l m
        @l s
        @l A
        @l K
        @l mol
        @l cd
        if !isempty(den)
            if isempty(num)
                write(io,"\\frac{1}{",join(den,"\\;"),"}")
            else
                write(io,"\\frac{",join(num,"\\;"),"}{",join(den,"\\;"),"}")
            end
        else
            write(io,join(num,"\\;"))
        end
    end

    function Base.Multimedia.writemime{T,m,kg,s,A,K,mol,cd}(io::IO,::MIME"text/mathtex+latex",x::SIQuantity{T,m,kg,s,A,K,mol,cd})
        writemime(io,MIME("text/mathtex+latex"),x.val)
        write(io,"\\;")
        Base.Multimedia.writemime(io,MIME("text/mathtex+latex"),unit(x))
    end

# Non-SI Units
immutable NonSIUnit{BaseUnit<:SIUnit,Unit}; end
immutable NonSIQuantity{T,Unit<:NonSIUnit} <: Number
    val::T
end

# Non-SI promote rules
promote_rule(x::Type{MathConst},y::Type{NonSIUnit}) = 
    NonSIQuantity{x,y}
promote_rule{sym,T,Unit}(x::Type{MathConst{sym}},y::Type{NonSIQuantity{T,Unit}}) = 
    NonSIQuantity{promote_type(MathConst{sym},T),Unit}

promote_rule{T,S,U1,U2}(
    A::Type{NonSIQuantity{T,U1}},B::Type{SIQuantity{S,U2}}) = NonSIQuantity{promote_type(T,S)}
promote_rule{T,U1}(
    A::Type{NonSIQuantity{T,U1}},U2::Type{NonSIUnit}) = NonSIQuantity{T}
promote_rule{S,U}(x::Type{Bool},y::Type{NonSIQuantity{S,U}}) = NonSIQuantity{promote_type(Bool,S),U}
promote_rule(x::Type{Bool},U::Type{NonSIUnit}) = NonSIQuantity{Bool,U}
promote_rule{T,S,U}(x::Type{T},y::Type{NonSIQuantity{S,U}}) = NonSIQuantity{promote_type(T,S),U}
promote_rule{T}(x::Type{T},U::Type{NonSIUnit}) = NonSIQuantity{T,U}

# Interaction between SI and non-SI quantities
promote_rule{S,T,U,m,kg,s,A,K,mol,cd}(x::Type{NonSIQuantity{S,U}},y::Type{SIQuantity{T,m,kg,s,A,K,mol,cd}}) = 
    SIQuantity{promote_type(S,T)}
promote_rule{S,T,U,m,kg,s,A,K,mol,cd}(x::Type{SIQuantity{T,m,kg,s,A,K,mol,cd}},y::Type{NonSIQuantity{S,U}}) = 
    SIQuantity{promote_type(S,T)}

siquantity{B}(T,U::NonSIUnit{B}) = quantity(T,B())
siquantity{B}(T,U::Type{NonSIUnit{B}}) = quantity(T,B())
convert{T,S,U}(::Type{SIQuantity{T}},x::NonSIQuantity{S,U}) = (siquantity(promote_type(T,S),U())(x.val))


*{T<:NonSIUnit}(x,t::T) = NonSIQuantity{typeof(x),T}(x)

unit{T,Unit}(x::NonSIQuantity{T,Unit}) = Unit()
quantity(T::Union(Type,TypeVar),x::NonSIUnit) = NonSIQuantity{T,typeof(x)}
quantity(T::Union(Type,TypeVar),U::Type{NonSIUnit}) = NonSIQuantity{T,U}

/(x::SIQuantity,y::NonSIUnit) = x/convert(SIQuantity,y)
/(x::NonSIUnit,y::SIQuantity) = convert(SIQuantity,x)/y

show{BaseUnit,Unit}(io::IO,x::NonSIUnit{BaseUnit,Unit}) = write(io,string(Unit))
function show(io::IO,x::NonSIQuantity)
    show(io,x.val)
    print(io," ")
    show(io,unit(x))
end

function Base.Multimedia.writemime{BaseUnit,Unit}(io::IO,::MIME"text/mathtex+latex",x::NonSIUnit{BaseUnit,Unit})
    write(io,"\\text{",string(Unit),"}")
end

function Base.Multimedia.writemime(io::IO,::MIME"text/mathtex+latex",x::NonSIQuantity)
    writemime(io,MIME("text/mathtex+latex"),x.val)
    write(io,"\\;")
    Base.Multimedia.writemime(io,MIME("text/mathtex+latex"),unit(x))
end

convert(::Type{SIQuantity},x::NonSIQuantity) = x.val * convert(SIQuantity,x)

export ElectronVolt, Celcius, as

# Energy Units

const ElectronVolt = NonSIUnit{typeof(Joule),:eV}()
convert(::Type{SIQuantity},::typeof(ElectronVolt)) = 1.60217656535e-19Joule

function as{U<:NonSIUnit}(x::SIQuantity,y::U)
    val = x/y
    @assert !(typeof(val)<:SIQuantity)
    NonSIQuantity{typeof(val),U}(val)
end

function as{U<:NonSIUnit,Q<:SIQuantity}(X::AbstractArray{Q},y::U)
    val = [x/y for x in X]
    @assert !(typeof(eltype(val))<:SIQuantity)
    NonSIQuantity{typeof(val),U}(val)
end

include("shortunits.jl")

end # module
