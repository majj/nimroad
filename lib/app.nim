

type
    HApp = ref object of RootObj
        config: TomlValueRef

proc newHApp(config: TomlValueRef): HApp = 

    return HApp(config: config)