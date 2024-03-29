require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './consts', (require, module, exports, __dirname, __filename) ->

  module.exports =
    registers: ['A', 'B', 'C', 'X', 'Y', 'Z', 'I', 'J']
    extended: [null, 'JSR', null, null, null, null, null, null, 'INT', 'IAG', 'IAS', 'RFI', 'IAQ', null, null, null,  'HWN', 'HWQ', 'HWI', 'PRINT']
    basic: [null, 'SET', 'ADD', 'SUB', 'MUL', 'MLI', 'DIV', 'DVI', 'MOD', 'MDI', 'AND', 'BOR', 'XOR', 'SHR', 'ASR', 'SHL', 'IFB', 'IFC', 'IFE', 'IFN', 'IFG', 'IFA', 'IFL', 'IFU', null, null, 'ADX', 'SBX', null, null, 'STI', 'STD']
