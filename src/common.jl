abstract ODEJLAlgorithm <: AbstractODEAlgorithm
immutable ode23Alg <: ODEJLAlgorithm end
immutable ode45Alg <: ODEJLAlgorithm end
immutable ode23sAlg <: ODEJLAlgorithm end
immutable ode78Alg <: ODEJLAlgorithm end

function solve{uType,tType,isinplace,algType<:ODEJLAlgorithm,F}(prob::AbstractODEProblem{uType,tType,isinplace,F},
    alg::algType,timeseries=[],ts=[],ks=[];dense=true,save_timeseries=true,
    saveat=tType[],timeseries_errors=true,reltol = 1e-5, abstol = 1e-8,
    dtmin = abs(prob.tspan[2]-prob.tspan[1])/1e-9,
    dtmax = abs(prob.tspan[2]-prob.tspan[1])/2.5,
    dt = 0.,norm = Base.vecnorm,
    kwargs...)

    tspan = prob.tspan

    if tspan[end]-tspan[1]<tType(0)
        error("final time must be greater than starting time. Aborting.")
    end

    u0 = prob.u0

    Ts = sort(unique([tspan[1];saveat;tspan[2]]))

    if save_timeseries
        points = :all
    else
        points = :specified
    end

    sizeu = size(prob.u0)

    if isinplace
        f = (t,u) -> (du = zeros(u); prob.f(t,u,du); vec(du))
    elseif uType <: AbstractArray
        f = (t,u) -> vec(prob.f(t,reshape(u,sizeu)))
    else
        f = prob.f
    end

    if uType <: AbstractArray
        u0 = vec(prob.u0)
    else
        u0 = prob.u0
    end

    if typeof(alg) <: ode23Alg
        ts,timeseries_tmp = ODE.ode23(f,u0,Ts,
                          norm = norm,
                          abstol=abstol,
                          reltol=reltol,
                          maxstep=dtmax,
                          minstep=dtmin,
                          initstep=dt,
                          points=points)
    elseif typeof(alg) <: ode45Alg
        ts,timeseries_tmp = ODE.ode45(f,u0,Ts,
                          norm = norm,
                          abstol=abstol,
                          reltol=reltol,
                          maxstep=dtmax,
                          minstep=dtmin,
                          initstep=dt,
                          points=points)
    elseif typeof(alg) <: ode78Alg
        ts,timeseries_tmp = ODE.ode78(f,u0,Ts,
                          norm = norm,
                          abstol=abstol,
                          reltol=reltol,
                          maxstep=dtmax,
                          minstep=dtmin,
                          initstep=dt,
                          points=points)
    elseif typeof(alg) <: ode23sAlg
        ts,timeseries_tmp = ODE.ode23s(f,u0,Ts,
                          norm = norm,
                          abstol=abstol,
                          reltol=reltol,
                          maxstep=dtmax,
                          minstep=dtmin,
                          initstep=dt,
                          points=points)
    end

    # Reshape the result if needed
    if uType <: AbstractArray
        timeseries = Vector{uType}(0)
        for i=1:length(timeseries_tmp)
            push!(timeseries,reshape(timeseries_tmp[i],sizeu))
        end
    else
        timeseries = timeseries_tmp
    end

    build_solution(prob,alg,ts,timeseries,
                 timeseries_errors = timeseries_errors)
end

export ODEJLAlgorithm, ode23Alg, ode23sAlg, ode45Alg, ode78Alg
