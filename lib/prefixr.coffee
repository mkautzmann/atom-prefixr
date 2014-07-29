querystring = require 'querystring'
http = require 'http'

module.exports =
  activate: ->
    atom.workspaceView.command 'prefixr:run', => @runPrefixr()

  runPrefixr: ->
    # Find active editor
    editor = atom.workspaceView.getEditorViews().filter (editor) ->
      editor.active
    return unless editor.length is 1
    editor = editor.shift().getEditor()
    grammar = editor.getGrammar().name
    return unless grammar is "CSS" or grammar is "SCSS"

    isWholeBuffer = editor.getSelectedText().length is 0
    selectedText = editor.getSelectedText() or editor.getText()

    data = querystring.stringify
      css: selectedText

    httpOptions =
      host: 'expressprefixr.herokuapp.com'
      port: 80
      method: 'POST'
      path: '/api/processor'
      headers:
        'Content-Type': 'application/x-www-form-urlencoded'
        'Content-Length': Buffer.byteLength data

    response = ''
    req = http.request httpOptions, (res) ->
      res.setEncoding('utf-8')
      res.on 'data', (result) ->
        result = JSON.parse(result)
        if result.status is 'success'
          if isWholeBuffer
            editor.setText(result.result)
          else
            editor.setTextInBufferRange(editor.getSelectedBufferRange(), result.result)
        else
          atom.confirm
            message: 'Your CSS could not be prefixd.'
            detailedMessage: error.result
            buttons:
              OK: null

      res.on 'error', (error) ->
        atom.confirm
          message: 'Could not reach ExpressPrefixr API'
          detailedMessage: error.message
          buttons:
            OK: null

    req.write data
    req.end()
