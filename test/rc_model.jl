using Test
using ModelingToolkit, OrdinaryDiffEq

# Basic electric components
@parameters t
function Pin(;name)
    @variables v(t) i(t)
    ODESystem(Equation[], t, [v, i], [], name=name, defaults=[v=>1.0, i=>1.0])
end

function Ground(name)
    @named g = Pin()
    eqs = [g.v ~ 0]
    ODESystem(eqs, t, [], [], systems=[g], name=name)
end

function ConstantVoltage(name; V = 1.0)
    val = V
    @named p = Pin()
    @named n = Pin()
    @parameters V
    eqs = [
           V ~ p.v - n.v
           0 ~ p.i + n.i
          ]
    ODESystem(eqs, t, [], [V], systems=[p, n], defaults=Dict(V => val), name=name)
end

function Resistor(name; R = 1.0)
    val = R
    @named p = Pin()
    @named n = Pin()
    @variables v(t)
    @parameters R
    eqs = [
           v ~ p.v - n.v
           0 ~ p.i + n.i
           v ~ p.i * R
          ]
    ODESystem(eqs, t, [v], [R], systems=[p, n], defaults=Dict(R => val), name=name)
end

function Capacitor(name; C = 1.0)
    val = C
    @named p = Pin()
    @named n = Pin()
    @variables v(t)
    @parameters C
    D = Differential(t)
    eqs = [
           v ~ p.v - n.v
           0 ~ p.i + n.i
           D(v) ~ p.i / C
          ]
    ODESystem(eqs, t, [v], [C], systems=[p, n], defaults=Dict(C => val), name=name)
end

R = 1.0
C = 1.0
V = 1.0
resistor = Resistor(:resistor, R=R)
capacitor = Capacitor(:capacitor, C=C)
source = ConstantVoltage(:source, V=V)
ground = Ground(:ground)

function connect(ps...)
    eqs = [
           0 ~ sum(p->p.i, ps) # KCL
          ]
    # KVL
    for i in 1:length(ps)-1
        push!(eqs, ps[i].v ~ ps[i+1].v)
    end

    return eqs
end
rc_eqs = [
          connect(source.p, resistor.p)
          connect(resistor.n, capacitor.p)
          connect(capacitor.n, source.n, ground.g)
         ]

rc_model = ODESystem(rc_eqs, t, systems=[resistor, capacitor, source, ground], name=:rc)
