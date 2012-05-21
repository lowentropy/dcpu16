PR['registerLangHandler'](
    PR['createSimpleLexer'](
        [
         ['opn',             /^\[/, null, '['],
         ['clo',             /^\]/, null, ']'],
         [PR['PR_COMMENT'],     /^;[^\r\n]*/, null, ';'],
         [PR['PR_PLAIN'],       /^[\t\n\r \xA0]+/, null, '\t\n\r \xA0'],
         [PR['PR_STRING'],      /^\"(?:[^\"\\]|\\[\s\S])*(?:\"|$)/, null, '"']
        ],
        [
         [PR['PR_KEYWORD'],     /^(?:set|add|sub|mul|mli|div|dvi|mod|mdi|and|bor|xor|shr|asr|shl|ifb|ifc|ife|ifn|ifg|ifa|ifl|ifu|adx|sbx|sti|std|jsr|int|iag|ias|rfi|iaq|hwn|hwq|hwi|dat|inc)$/i, null],
         [PR['PR_LITERAL'],     /^[+\-]?(?:[0#]x[0-9a-f]+|\d+\/\d+|(?:\.\d+|\d+(?:\.\d*)?)(?:[ed][+\-]?\d+)?)/i],
         [PR['PR_TYPE'],        /^(?:a|b|c|x|y|z|i|a|pc|sp|ex)$/i, null],
         [PR['PR_LITERAL'],     /^:[a-z0-9_]+/i],
         [PR['PR_PLAIN'],       /^[a-z_][a-z0-9_]+/i],
         [PR['PR_PUNCTUATION'], /^[^\w\t\n\r \xA0\"\\\']+/]
        ]),
    ['dasm', 'dasm16']);
