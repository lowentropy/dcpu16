require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './devices/lem1802', (require, module, exports, __dirname, __filename) ->

  module.exports = class LEM1802
    constructor: (@emu, @adapter) ->
      @border_color = @default_border_color
      @blink_interval = @default_blink_interval
      @font_address = 0
      @palette_address = 0
      @screen_address = null

    name: 'LEM1802 - Low Energy Monitor'
    hardware_id: 0x7349f615
    version_id: 0x1802
    manufacturer_id: 0x1c6c8b36
  
    start: ->
      @reverse = false
      setInterval (=> @blink()), @blink_interval
    
    blink: ->
      @reverse = !@reverse
      @render()
  
    render: ->
      return unless @screen_address
      addr = @screen_address
      console.log "RENDER, base =", addr # XXX
      for row in [0...12]
        for col in [0...32]
          @render_cell addr++
      @adapter?.refresh()
  
    render_cell: (addr, word) ->
      base = addr - @screen_address
      x = base & 0x1f
      y = base >> 5
      word ?= @emu.mem_get addr
      f     = (word & 0xf000) >> 12
      b     = (word & 0x0f00) >> 8
      blink = (word & 0x0080) >> 7
      char  = (word & 0x007f)
      glyph = @char(char)
      [f,b] = [b,f] if blink && @reverse
      f = @color f
      b = @color b
      @render_glyph glyph, f, b, x, y
  
    render_glyph: (g, f, b, xb, yb) ->
      x = xb - 1
      for i in [1..4]
        x++
        y = yb
        for j in [1..8]
          c = if g & 0x80000000 then f else b
          @adapter?.draw x, y, c
          g <<= 1

    char: (index) ->
      if @font_address
        @emu.mem_get(@font_address + index)
      else
        @default_font[index]
  
    color: (index) ->
      raw = if @palette_address
        @emu.mem_get(@palette_address + index)
      else
        @default_palette[index]
      r = ((raw & 0x0f00) >> 8) * 17
      g = ((raw & 0x00f0) >> 4) * 17
      b = ((raw & 0x000f) >> 0) * 17
      [r,g,b]
  
    send_interrupt: ->
      switch @emu.a.get()
        when 0 then @mem_map_screen()
        when 1 then @mem_map_font()
        when 2 then @mem_map_palette()
        when 3 then @set_border_color()
  
    mem_map_screen: ->
      @emu.remove_mem_trigger @screen_trigger
      if @screen_address = @emu.b.get()
        @screen_trigger = @emu.mem_trigger @screen_address, @screen_address+0x180, (addr, word) =>
          @render_cell addr, word
          @adapter?.refresh()
      @render()
  
    mem_map_font: ->
      @emu.remove_trigger @font_trigger
      if @font_address = @emu.b.get()
        @font_trigger = @emu.mem_trigger @font_address, @font_address+0x100, =>
          @render()
      @render()
  
    mem_map_palette: ->
      @emu.remove_trigger @palette_trigger
      if @palette_address = @emu.b.get()
        @palette_trigger = @emu.mem_trigger @palette_address, @palette_address+0x10, =>
          @render()
      @render()
  
    set_border_color: ->
      @border_color = @emu.b.get() & 0xF
  
    halt: ->
    pause: ->
    resume: ->
    
    default_blink_interval: 1000
    default_char: ' '
    default_word: 0xF020
    default_border_color: 0x1
  
    default_palette: [
      0X0000, 0X000A, 0X00A0, 0X00AA, 0X0A00, 0X0A0A, 0X0A50, 0X0AAA
      0X0555, 0X055F, 0X05F5, 0X05FF, 0X0F55, 0X0F5F, 0X0FF5, 0X0FFF
    ]
  
    default_font: [
      0xB79E388E, 0x722C75F4, 0x19BB7F8F, 0x85F9B158
      0x242E2400, 0x082A0800, 0x00080000, 0x08080808
      0x00FF0000, 0x00F80808, 0x08F80000, 0x080F0000
      0x000F0808, 0x00FF0808, 0x08F80808, 0x08FF0000
      0x080F0808, 0x08FF0808, 0x663399CC, 0x993366CC
      0xFEF8E080, 0x7F1F0701, 0x01071F7F, 0x80E0F8FE
      0x5500AA00, 0x55AA55AA, 0xFFAAFF55, 0x0F0F0F0F
      0xF0F0F0F0, 0x0000FFFF, 0xFFFF0000, 0xFFFFFFFF
      0x00000000, 0x005F0000, 0x03000300, 0x3E143E00
      0x266B3200, 0x611C4300, 0x36297650, 0x00020100
      0x1C224100, 0x41221C00, 0x14081400, 0x081C0800
      0x40200000, 0x08080800, 0x00400000, 0x601C0300
      0x3E493E00, 0x427F4000, 0x62594600, 0x22493600
      0x0F087F00, 0x27453900, 0x3E493200, 0x61190700
      0x36493600, 0x26493E00, 0x00240000, 0x40240000
      0x08142200, 0x14141400, 0x22140800, 0x02590600
      0x3E595E00, 0x7E097E00, 0x7F493600, 0x3E412200
      0x7F413E00, 0x7F494100, 0x7F090100, 0x3E417A00
      0x7F087F00, 0x417F4100, 0x20403F00, 0x7F087700
      0x7F404000, 0x7F067F00, 0x7F017E00, 0x3E413E00
      0x7F090600, 0x3E617E00, 0x7F097600, 0x26493200
      0x017F0100, 0x3F407F00, 0x1F601F00, 0x7F307F00
      0x77087700, 0x07780700, 0x71494700, 0x007F4100
      0x031C6000, 0x417F0000, 0x02010200, 0x80808000
      0x00010200, 0x24547800, 0x7F443800, 0x38442800
      0x38447F00, 0x38545800, 0x087E0900, 0x48543C00
      0x7F047800, 0x047D0000, 0x20403D00, 0x7F106C00
      0x017F0000, 0x7C187C00, 0x7C047800, 0x38443800
      0x7C140800, 0x08147C00, 0x7C040800, 0x48542400
      0x043E4400, 0x3C407C00, 0x1C601C00, 0x7C307C00
      0x6C106C00, 0x4C503C00, 0x64544C00, 0x08364100
      0x00770000, 0x41360800, 0x02010201, 0x02050200
    ]