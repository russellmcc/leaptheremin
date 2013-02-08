require [], ->

  window.WebSocket ?= MozWebSocket
  window.AudioContext ?= webkitAudioContext

  # setup spooky sine wave
  ac = new AudioContext()
  osc = ac.createOscillator()
  g = ac.createGainNode()
  osc.connect g
  g.connect ac.destination
  osc.frequency.value = 0
  g.gain.value = 0
  osc.start(0)
  
  set = no

  # get the dist between to points
  distTo = (a, b) ->
    sqr = (x) -> (x*x)
    sum = 0
    sum += sqr(a[i] - b[i]) for i in [0..2]
    Math.sqrt sum

  maxD = 600

  # get the loudness given a distance in mm
  dToLoudness = (d) ->
    return Math.max(0, Math.min(1, (d-50)/maxD))

  dToPitch = (d) ->
    return Math.pow(2, 11*(1-d/800))

  handleLeapMsg = (msg) ->
    return if not msg.hands?
    
    pitch = 0
    loudness = 0
    outputStr = ""
      
    if msg.hands.length isnt 0
      minD1 = maxD
      minD2 = maxD
      for hand in msg.hands
        pos = hand.palmPosition
        d1 = distTo [pos[0], 0, pos[2]], [200, 0, -50]
        d2 = distTo [0, pos[1], pos[2]], [0, 250, -100]
        minD1 = Math.min(d1, minD1)
        minD2 = Math.min(d2, minD2)
        outputStr += "#{Math.round pos[0]} #{Math.round pos[1]} #{Math.round pos[2]}<br/>"
      pitch = dToPitch minD1
      loudness = dToLoudness minD2
      outputStr += "MINs: #{Math.round minD1} #{Math.round minD2}<br/>"
      outputStr += "VALs: #{Math.round pitch} #{Math.round loudness * 1000}"
#    $('#output').html(outputStr)
    $('body').css backgroundColor: "rgb(#{0}, #{Math.round pitch / 2000 * 255}, #{Math.round loudness * 255})"
    osc.frequency.value = pitch
    g.gain.value = if(loudness < .05) then 0 else loudness
     
  $ ->
    ws = new WebSocket("ws://localhost:6437/")
    ws.onopen = (event) ->
      console.log 'opened socket!'
  
    ws.onmessage = (event) ->
      handleLeapMsg JSON.parse(event.data)
  