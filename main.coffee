#!vanilla

# See: http://www.loria.fr/~rougier/teaching/numpy/scripts/gray-scott.py

class Model

    N: 62
    r: 20
    
    rep = (x, n) -> ((x for [1..n]) for [1..n])
    zeros = (n) -> rep 0, n
    
    constructor: (@F=0.06, @k=0.062, @Du=0.19, @Dv=0.05) ->
        z = => zeros(@N+2)
        @U = z()
        @V = z()
        @du = z()
        @dv = z()
        @reset @F, @k
        
    reset: (@F, @k) ->
        @initCond(@U, 1, 0.5)
        @initCond(@V, 0, 0.25)  
        
    initCond: (X, outVal, inVal) ->
        for m in [1..@N]
            for n in [1..@N]
                X[m][n] = outVal
        R = [@N/2-@r..@N/2+@r-1]
        for m in R
            for n in R
                X[m][n] = inVal + 0.4*Math.random()
                
    L: (X, m, n) -> 
        X[m][n-1] + X[m][n+1] + X[m-1][n] + X[m+1][n] - 4*X[m][n]
        
    inc: (X, dx) ->
        for m in [1..@N]
            for n in [1..@N]
                X[m][n] += dx[m][n]

    step: (iterations) ->
        for i in [1..iterations]
            for m in [1..@N]
                for n in [1..@N]
                    Lu = @L(@U, m, n)
                    Lv = @L(@V, m, n)
                    UVV = @U[m][n]*@V[m][n]*@V[m][n]
                    @du[m][n] = @Du*Lu - UVV + @F*(1-@U[m][n])
                    @dv[m][n] = @Dv*Lv + UVV - (@F+@k)*@V[m][n]
            @inc @U, @du
            @inc @V, @dv

class Heatmap

    px: 4
    
    constructor: (@id, @V) ->
        @N = @V.length - 2
        @initData()
        $("#container").empty()
        @heat = simpleheat(@id)
            .data(@data)
            .max(0.75)
            .radius(@px, @px)
    
    initData: ->
        @data = []
        for m in [0..@N+1]
            for n in [0..@N+1]
                @data.push [n*@px, m*@px, @V[m][n]]
      
    mapModel: ->
        i = 0
        for m in [0..@N+1]
            for n in [0..@N+1]
                @data[i][2] = @V[m][n]
                i++
    
    draw: ->
        @mapModel()
        @heat.draw()
        

class Simulation

    canvasId: "canvas"
    iterationsPerSnapshot: 20
    delay: 2000
    tSnapshot: 40
    
    pFamily: [
        {s: "alpha",   F: 0.02,  k: 0.05}
        {s: "epsilon", F: 0.02,  k: 0.06}      
        {s: "kappa",F: 0.04, k: 0.06}
    ]

    constructor: (@numSnapshots=100) ->
        @clear()
        @pIndex = 0
        @setParams()
        @model = new Model @F, @k
        @heatmap = new Heatmap @canvasId, @model.V
        @heatmap.draw()
        @initButton()
        $blab.simTId = setTimeout (=> @start()), @delay
        
    clear: ->
        clearTimeout $blab.simTId if $blab.simTId
        
    initButton: ->
        canvas = $("##{@canvasId}")
        canvas.unbind()
        canvas.click =>
            @pIndex++
            @pIndex = 0 if @pIndex > @pFamily.length-1
            @setParams()
            @reset @F, @k
            
    setParams: ->
        params = @pFamily[@pIndex]
        @F = params.F
        @k = params.k
        $("#param_text").html "F=#{@F}, k=#{@k}"
        
    start: ->
        @snapshot = 0
        @run()
        
    reset: (@F, @k) ->
        @clear()
        @model.reset @F, @k
        @start()

    run: ->
        return if @snapshot++ > @numSnapshots
        @model.step @iterationsPerSnapshot
        @heatmap.draw()
        $blab.simTId = setTimeout (=> @run()), @tSnapshot  # Recursion

new Simulation

$("#coffee_link").click -> $blab.show "Coffee", on

