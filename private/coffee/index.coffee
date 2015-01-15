$ = require 'jquery'
Game = require './game'

debug = true
fadeDuration = 200

$ ->
  # Global variables
  $page = {}
  data = {}
  # mode = { 'easy', 'hard' }
  mode = ''
  game = undefined

  # Sets up the website for the first time
  setup = ->
    $page =
      intro: $ '.page.intro'
      game: $ '.page.game'
      results: $ '.page.results'

    setPage 'intro', false

    $easyButton = $('.easy.button')
    $hardButton = $('.hard.button')
    $skipButton = $('.skip.button')
    $againButton = $('.again.button')

    # Load the data then enable intro button clicks
    loadData ->
      $easyButton.click ->
        startGame('easy')
      $hardButton.click ->
        startGame('hard')
      $skipButton.click ->
        game.nextQuestion()
      $againButton.click ->
        $('ul.people').empty()
        setPage 'intro'

    # Listen for keyboard events
    $('body').keydown (e) ->
      # Check backspace
      if e.which == 8
        backspace = true
      else
        char = String.fromCharCode(e.which).toLowerCase()
      if game
        if backspace
          game.removeChar()
          return false
        else if game.isValidChar(char)
          game.addChar(char)


  # Starts a new game
  startGame = (difficulty) ->
    mode = difficulty
    setPage('game')
    game = new Game(data, $page.game)
    game.setDifficulty difficulty
    game.nextQuestion()
    game.setGameOverCb ->
      setPage 'results'
      results = game.getResults()
      $peopleList = []

      addList = (list, type) ->
        for people in list
          $picture = $('<img>').addClass('picture').attr('src', people.image)
          $name = $('<h3>').addClass('name').text(people.firstName)
          $person = $('<li>').addClass('person ' + type).append($picture, $name)
          $('ul.people').append($person)
      
      addList results.incorrect, 'incorrect'
      addList results.correct, 'correct'

      $page.results.find('.fraction .current').text(results.score)
      $page.results.find('.fraction .total').text(results.total)


  # Loads the data for the game
  loadData = (cb) ->
    if debug
      data = require '../../public/data/data'
      cb()
    else
      $.getJSON '/api', (response) ->
        data = response
        cb()

  # Sets the state of the pages
  setPage = (newPageName, transition = true) ->
    for pageName of $page
      if pageName is newPageName
        if transition
          $page[pageName].fadeIn(fadeDuration)
        else
          $page[pageName].show()
      else
        if transition
          $page[pageName].fadeOut(fadeDuration)
        else
          $page[pageName].hide()


  setup()