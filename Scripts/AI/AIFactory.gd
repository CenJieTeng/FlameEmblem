class_name AIFactory

static func create_ai(brain: AIBrain, strategy_type: AIBrain.AIStrategy) -> AIStrategyBase:
    match strategy_type:
        AIBrain.AIStrategy.AGGRESSIVE:
            return AggressiveAI.new(brain)
        AIBrain.AIStrategy.STATIC:
            return StaticAI.new(brain)
        _:
            printerr("未知的AI策略类型: %s" % str(strategy_type))
            return null