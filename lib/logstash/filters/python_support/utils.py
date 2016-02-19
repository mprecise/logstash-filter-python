def get_attr(_object, _attr_name):
    return getattr(_object, _attr_name)


def call_function(_module, _func_name, _obj):
    return getattr(_module, _func_name)(_obj)

