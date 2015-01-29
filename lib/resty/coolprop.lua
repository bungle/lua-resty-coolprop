local ffi        = require "ffi"
local ffi_new    = ffi.new
local ffi_str    = ffi.string
local ffi_load   = ffi.load
local ffi_cdef   = ffi.cdef
local ffi_typeof = ffi.typeof
local huge       = math.huge

ffi_cdef[[
double Props1SI(const char *FluidName, const char* Output);
double PropsSI(const char *Output, const char *Name1, double Prop1, const char *Name2, double Prop2, const char *Ref);
long   PhaseSI(const char *Name1, double Prop1, const char *Name2, double Prop2, const char *Ref, char *phase, int n);
long   get_global_param_string(const char *param, char *Output, int n);
long   get_parameter_information_string(const char *key, char *Output, int n);
long   get_mixture_binary_pair_data(const char *CAS1, const char *CAS2, const char *key);
long   get_fluid_param_string(const char *fluid, const char *param, char *Output, int n);
int    set_reference_stateS(const char *Ref, const char *reference_state);
int    set_reference_stateD(const char *Ref, double T, double rho, double h0, double s0);
double F2K(double T_F);
double K2F(double T_K);
long   get_param_index(const char *param);
long   redirect_stdout(const char *file);
int    get_debug_level();
void   set_debug_level(int level);
double saturation_ancillary(const char *fluid_name, const char *output, int Q, const char *input, double value);
double HAPropsSI(const char *Output, const char *Name1, double Prop1, const char *Name2, double Prop2, const char *Name3, double Prop3);
]]

local but = ffi_typeof "char[?]"
local buf = ffi_new(but, 256)
local bub = ffi_new(but, 4096)
local lib = ffi_load "/Users/bungle/Sources/CoolProp-official/build/libCoolProp.dylib"

local debug = setmetatable({}, {
    __index = function(_, n)
        if n == "level" then
            return lib.get_debug_level()
        end
        return nil
    end,
    __newindex = function(_, k, v)
        if k == "level" then
            lib.set_debug_level(v)
        end
        rawset(_, k, v)
    end
})

local coolprop = { debug = debug }

function coolprop.props1(fluidname, output)
    local v = lib.Props1SI(fluidname, output)
    if v == huge then
        return nil, coolprop.error()
    else
        return v
    end
end

coolprop.Props1SI = coolprop.props1

function coolprop.props(output, name1, prop1, name2, prop2, ref)
    local v = lib.PropsSI(output, name1, prop1, name2, prop2, ref)
    if v == huge then
        return nil, coolprop.error()
    else
        return v
    end
end

coolprop.PropsSI = coolprop.props

function coolprop.phase(name1, prop1, name2, prop2, ref)
    if lib.PhaseSI(name1, prop1, name2, prop2, ref or "", buf, 256) == 1 then
        return ffi_str(buf)
    end
    return nil
end

coolprop.PhaseSI = coolprop.phase

function coolprop.global(param)
    if lib.get_global_param_string(param, bub, 4096) == 1 then
        return ffi_str(bub)
    end
    return nil
end

coolprop.get_global_param_string = coolprop.global

function coolprop.param(key)
    if lib.get_parameter_information_string(key, bub, 4096) == 1 then
        return ffi_str(bub)
    end
    return nil
end

coolprop.get_parameter_information_string = coolprop.param

function coolprop.mixture(cas1, cas2, key)
    return tonumber(lib.get_mixture_binary_pair_data(cas1, cas2, key))
end

coolprop.get_mixture_binary_pair_data = coolprop.mixture

function coolprop.fluid(fluid, param)
    assert(lib.get_fluid_param_string(fluid, param, bub, 4096) == 1)
    return ffi_str(bub)
end

coolprop.get_fluid_param_string = coolprop.fluid

function coolprop.states(ref, state)
    return lib.set_reference_stateS(ref, state) == 1
end

coolprop.set_reference_stateS = coolprop.states

function coolprop.stated(ref, t, rho, h0, s0)
    return lib.set_reference_stateD(ref, t, rho, h0, s0) == 1
end

function coolprop.f2k(f)
    return lib.F2K(f)
end

coolprop.F2K = coolprop.f2k

function coolprop.k2f(k)
    return lib.K2F(k)
end

coolprop.K2F = coolprop.k2f

function coolprop.index(param)
    return tonumber(lib.get_param_index(param))
end

coolprop.get_param_index = coolprop.index

function coolprop.saturation(fluid, output, q, input, value)
    return lib.saturation_ancillary(fluid, output, q, input, value)
end

coolprop.saturation_ancillary = coolprop.saturation

function coolprop.output(file)
    return lib.redirect_stdout(file) == 1
end

coolprop.redirect_stdout = strout

function coolprop.get_debug_level()
    return coolprop.debug.level
end

function coolprop.set_debug_level(level)
    coolprop.debug.level = level
end

function coolprop.haprops(output, name1, prop1, name2, prop2, name3, prop3)
    local v = lib.HAPropsSI(output, name1, prop1, name2, prop2, name3, prop3)
    if v == huge then
        return nil, coolprop.error()
    else
        return v
    end
end

coolprop.HAPropsSI = coolprop.haprops

function coolprop.error()
    return coolprop.get_global_param_string("errstring")
end

return coolprop
