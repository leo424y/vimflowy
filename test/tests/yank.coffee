TestCase = require '../testcase.coffee'
Register = require '../../assets/js/register.coffee'

describe "yank", () ->
  describe "characters", () ->
    it "works in basic case", () ->
      t = new TestCase ['px']
      t.sendKeys 'xp'
      t.expect ['xp']
      t.expectRegisterType Register.TYPES.CHARS
      t.sendKeys 'xp'
      t.expect ['xp']

    it "works with deleting words", () ->
      t = new TestCase ['one fish, two fish, red fish, blue fish']
      t.sendKeys 'dWWhp'
      t.expect ['fish, one two fish, red fish, blue fish']
      # undo doesn't move cursor, and paste still has stuff in register
      t.sendKeys 'up'
      t.expect ['fish, one two fish, red fish, blue fish']

      t = new TestCase ['one fish, two fish, red fish, blue fish']
      t.sendKeys '2dW2Whp'
      t.expect ['two fish, one fish, red fish, blue fish']
      # undo doesn't move cursor, and paste still has stuff in register
      t.sendKeys 'up'
      t.expect ['two fish, one fish, red fish, blue fish']

      t = new TestCase ['one fish, two fish, red fish, blue fish']
      t.sendKeys 'd2W2Whp'
      t.expect ['two fish, one fish, red fish, blue fish']
      # undo doesn't move cursor, and paste still has stuff in register
      t.sendKeys 'u'
      # type hasnt changed
      t.expectRegisterType Register.TYPES.CHARS
      t.sendKeys 'p'
      t.expect ['two fish, one fish, red fish, blue fish']

    it "works behind", () ->
      t = new TestCase ['one fish, two fish, red fish, blue fish']
      t.sendKeys '$F,d$3bP'
      t.expect ['one fish, two fish, blue fish, red fish']
      # undo doesn't move cursor, and paste still has stuff in register
      t.sendKeys 'uP'
      t.expect ['one fish, two fish, blue fish, red fish']

    it "works behind in an edge case with empty line, and repeat", () ->
      t = new TestCase ['word']
      t.sendKeys 'de'
      t.expect ['']
      t.sendKeys 'P'
      t.expect ['word']
      t.sendKeys 'u'
      t.expect ['']
      # repeat still knows what to do
      t.sendKeys '.'
      t.expect ['word']
      t.sendKeys '.'
      t.expect ['worwordd']

    it "works with motions", () ->
      t = new TestCase ['lol']
      t.sendKeys 'yllp'
      t.expect ['loll']

      t = new TestCase ['lol']
      t.sendKeys 'y$P'
      t.expect ['lollol']

      t = new TestCase ['lol']
      t.sendKeys '$ybp'
      t.expect ['lollo']
      t.sendKeys 'u'
      t.expect ['lol']
      t.sendKeys 'P'
      t.expect ['lolol']

      t = new TestCase ['haha ... ha ... funny']
      t.sendKeys 'y3wP'
      t.expect ['haha ... ha haha ... ha ... funny']

      t = new TestCase ['haha ... ha ... funny']
      t.sendKeys 'yep'
      t.expect ['hhahaaha ... ha ... funny']
      # cursor ends at last character
      t.sendKeys 'yffp'
      t.expect ['hhahaaaha ... ha ... faha ... ha ... funny']

  describe "rows", () ->
    it "works in a basic case", () ->
      t = new TestCase ['humpty', 'dumpty']
      t.sendKeys 'dd'
      t.expectRegisterType Register.TYPES.CLONED_ROWS
      t.expect [ 'dumpty' ]
      t.sendKeys 'p'
      t.expectRegisterType Register.TYPES.CLONED_ROWS
      t.expect [ 'dumpty', 'humpty' ]
      t.sendKeys 'u'
      t.expect ['dumpty']
      t.sendKeys 'u'
      t.expect ['humpty', 'dumpty']
      # violates cloning constraints
      t.sendKeys 'p'
      t.expect ['humpty', 'dumpty']

    it "works behind", () ->
      t = new TestCase ['humpty', 'dumpty']
      t.sendKeys 'jddP'
      t.expect [ 'dumpty', 'humpty' ]
      t.sendKeys 'u'
      t.expect ['humpty']
      t.sendKeys 'u'
      t.expect ['humpty', 'dumpty']

    it "pastes siblings, not children", () ->
      t = new TestCase [
        { text: 'herpy', children: [
          { text: 'derpy', children: [
            'burpy'
          ] },
        ] },
      ]
      t.sendKeys 'jjddp'
      t.expect [
        { text: 'herpy', children: [
          'derpy',
          'burpy'
        ] },
      ]

      t.sendKeys 'u'
      t.expect [
        { text: 'herpy', children: [
          'derpy',
        ] },
      ]
      t.sendKeys 'kp'
      t.expect [
        { text: 'herpy', children: [
          'burpy',
          'derpy'
        ] },
      ]

      t.sendKeys 'u'
      t.expect [
        { text: 'herpy', children: [
          'derpy',
        ] },
      ]
      t.sendKeys 'P'
      t.expect [
        'burpy'
        { text: 'herpy', children: [
          'derpy',
        ] },
      ]
      t.sendKeys 'u'
      t.expect [
        { text: 'herpy', children: [
          'derpy',
        ] },
      ]
      t.sendKeys 'jP'
      t.expect [
        { text: 'herpy', children: [
          'burpy',
          'derpy',
        ] },
      ]

    it "pastes register of recent action after undo", () ->
      t = new TestCase ['hey', 'yo', 'yo', 'yo', 'yo', 'yo']
      t.sendKeys 'yyjp'
      t.expect ['hey', 'yo', 'hey', 'yo', 'yo', 'yo', 'yo']
      t.sendKeys 'jjP'
      t.expect ['hey', 'yo', 'hey', 'yo', 'hey', 'yo', 'yo', 'yo']
      # this should only affect one of the pasted lines (verify it's a copy!)
      t.sendKeys 'x'
      t.expect ['hey', 'yo', 'hey', 'yo', 'ey', 'yo', 'yo', 'yo']
      t.sendKeys 'uu'
      t.expect ['hey', 'yo', 'hey', 'yo', 'yo', 'yo', 'yo']
      t.sendKeys 'u'
      t.expect ['hey', 'yo', 'yo', 'yo', 'yo', 'yo']
      t.sendKey 'ctrl+r'
      t.expect ['hey', 'yo', 'hey', 'yo', 'yo', 'yo', 'yo']
      # the register still contains the 'h' from the 'x'
      t.sendKeys 'jjjjjp'
      t.expect ['hey', 'yo', 'hey', 'yo', 'yo', 'yo', 'yho']

      # similar to above case
      t = new TestCase ['hey', 'yo', 'yo', 'yo', 'yo', 'yo']
      t.sendKeys 'yyjp'
      t.expect ['hey', 'yo', 'hey', 'yo', 'yo', 'yo', 'yo']
      t.sendKeys 'jjP'
      t.expect ['hey', 'yo', 'hey', 'yo', 'hey', 'yo', 'yo', 'yo']
      t.sendKeys 'ry'
      t.expect ['hey', 'yo', 'hey', 'yo', 'yey', 'yo', 'yo', 'yo']
      t.sendKeys 'uu'
      t.expect ['hey', 'yo', 'hey', 'yo', 'yo', 'yo', 'yo']
      t.sendKeys 'u'
      t.expect ['hey', 'yo', 'yo', 'yo', 'yo', 'yo']
      # splice does NOT replace register!
      t.sendKeys 'jjjjjp'
      t.expect ['hey', 'yo', 'yo', 'yo', 'yo', 'yo', 'hey']

    it "works in basic case", () ->
      t = new TestCase [
        { text: 'hey', children: [
          'yo'
        ] }
      ]
      t.sendKeys 'yyp'
      t.expect [
        { text: 'hey', children: [
          'hey'
          'yo'
        ] }
      ]

    it "works recursively", () ->
      t = new TestCase [
        { text: 'hey', children: [
          'yo'
        ] }
      ]
      t.sendKeys 'yrp'
      t.expect [
        { text: 'hey', children: [
          { text: 'hey', children: [
            'yo'
          ] },
          'yo'
        ] }
      ]
      t.sendKeys 'p'
      t.expect [
        { text: 'hey', children: [
          { text: 'hey', children: [
            { text: 'hey', children: [
              'yo'
            ] },
            'yo'
          ] },
          'yo'
        ] }
      ]
      t.sendKeys 'u'
      t.expect [
        { text: 'hey', children: [
          { text: 'hey', children: [
            'yo'
          ] },
          'yo'
        ] }
      ]
      t.sendKey 'ctrl+r'
      t.expect [
        { text: 'hey', children: [
          { text: 'hey', children: [
            { text: 'hey', children: [
              'yo'
            ] },
            'yo'
          ] },
          'yo'
        ] }
      ]

    it "preserves collapsedness, and doesn't paste as child of collapsed", () ->
      t = new TestCase [
        { text: 'hey', collapsed: true, children: [
          'yo'
        ] }
      ]
      t.sendKeys 'yrp'
      t.expect [
        { text: 'hey', collapsed: true, children: [
          'yo'
        ] }
        { text: 'hey', collapsed: true, children: [
          'yo'
        ] },
      ]

    it "preserves collapsedness", () ->
      t = new TestCase [
        { text: 'hey', collapsed: true, children: [
          'yo'
        ] }
      ]
      t.sendKeys 'yrzp'
      t.expect [
        { text: 'hey', children: [
          { text: 'hey', collapsed: true, children: [
            'yo'
          ] },
          'yo'
        ] }
      ]

    it "pastes clones", () ->
      t = new TestCase [
        { text: 'hey', collapsed: true, children: [
          'yo'
        ] }
        'yo'
        { text: 'what', children: [
          'up'
        ] }
      ]
      t.sendKeys 'Vjd'
      t.expect [
        { text: 'what', children: [
          'up'
        ] }
      ]
      t.expectRegisterType Register.TYPES.CLONED_ROWS
      t.sendKeys 'P'
      t.expect [
        { text: 'hey', collapsed: true, children: [
          'yo'
        ] }
        'yo'
        { text: 'what', children: [
          'up'
        ] }
      ]
      t.sendKeys 'zryjrh'
      t.expect [
        { text: 'yey', children: [
          'ho'
        ] }
        'yo'
        { text: 'what', children: [
          'up'
        ] }
      ]
      # second paste should be changed thing
      t.sendKeys 'GP'
      t.expect [
        { text: 'yey', id: 1, children: [
          'ho'
        ] }
        { text: 'yo', id: 3 }
        { text: 'what', children: [
          { clone: 1 }
          { clone: 3 }
          'up'
        ] }
      ]

    it "yanks serialized (not cloned)", () ->
      t = new TestCase [
        { text: 'hey', collapsed: true, children: [
          'yo'
        ] }
        'yo'
        { text: 'what', children: [
          'up'
        ] }
      ]
      t.sendKeys 'Vjy'
      t.expectRegisterType Register.TYPES.SERIALIZED_ROWS
      t.sendKeys 'gg'
      t.sendKeys 'zryjrh'
      t.expect [
        { text: 'yey', children: [
          'ho'
        ] }
        'yo'
        { text: 'what', children: [
          'up'
        ] }
      ]
      # second paste should be changed thing
      t.sendKeys 'GP'
      t.expect [
        { text: 'yey', children: [
          'ho'
        ] }
        'yo'
        { text: 'what', children: [
          { text: 'hey', collapsed: true, children: [
            'yo'
          ] }
          'yo'
          'up'
        ] }
      ]
