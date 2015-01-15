$ = require 'jquery'
shuffle = require 'shuffle-array'
ucfirst = require 'ucfirst'
sets = require 'simplesets'

delayBetweenQuestions = 500

class Game
  constructor: (data, @$page) ->
    @questionDataOrder = shuffle(data)
    @currentQuestionIndex = -1
    @score = 0
    @guess = ''
    @correctGuessIndices = []

    # Generate valid character
    @validCharacters = new sets.Set()
    for char in 'abcdefghijklmnopqrstuvwxyz'
      @validCharacters.add(char)
    for questionData in @questionDataOrder
      for char in questionData.name
        @validCharacters.add(char.toLowerCase())
    @validCharacters.remove(' ')

    # Add first and last name to data structure
    for i, questionData of @questionDataOrder
      splitName = questionData.name.split(' ')
      @questionDataOrder[i].firstName = splitName[0]
      @questionDataOrder[i].lastName = splitName[1]

    @$name = @$page.find('.person .name')

    # Reset DOM
    @$page.find('.progress .total').text(@questionDataOrder.length)

  # Sets the game difficulty
  setDifficulty: (@difficulty) ->
    if @difficulty == 'easy'
      @$page.find('.person .picture').show()
      @$page.find('.person .title').show()
      @$page.find('.person .name').show()
      @$page.find('.person .description').hide()
    else if @difficulty == 'hard'
      @$page.find('.person .picture').hide()
      @$page.find('.person .title').hide()
      @$page.find('.person .name').show()
      @$page.find('.person .description').show()

  # Gets the current question data
  getQuestion: ->
    @questionDataOrder[@currentQuestionIndex]

  # Loads the next person (if available)
  nextQuestion: ->
    ++@currentQuestionIndex
    if @gameIsOver()
      @gameOverCb()
    else
      questionData = @getQuestion()
      @guess = ''
      
      # Update DOM
      if @difficulty == 'easy'
        @$page.find('.person .picture').attr('src', questionData.image)
        @$page.find('.person .title').text(questionData.title)
      else if @difficulty == 'hard'
        @$page.find('.person .description').text(questionData.description)
        
      @$name.removeClass('correct incorrect')
      @updateGuess()

  # ## Guessing

  # Returns true if the character is a valid guess
  isValidChar: (char) ->
    return @validCharacters.has(char)

  # Adds a character to the guess
  addChar: (char) ->
    @guess += char
    @guess = @guess.substring(0, @getQuestion().firstName.length)
    @checkGuess()

  # Removes a character from the guess
  removeChar: ->
    @guess = @guess.substring(0, @guess.length - 1)
    @checkGuess()

  # Checks if a guess is correct
  checkGuess: ->
    if !@transitioning
      @updateGuess()
      if @guessIsCorrect()
        @correctGuessIndices.push @currentQuestionIndex
        # Make name flash green
        @$page.find('.person .name').addClass('correct')
        @transitioning = true
        # Delay next question
        setTimeout =>
          @transitioning = false
          @$page.find('.progress .current').text(++@score)
          @nextQuestion()
        , delayBetweenQuestions
      else # incorrect
        firstName = @getQuestion().firstName
        if @guess.length == firstName.length
          @$page.find('.person .name').addClass('incorrect')
          @transitioning = true
          @$page.find('.person .name').text(firstName)
          setTimeout =>
            @transitioning = false
            @nextQuestion()
          , delayBetweenQuestions * 2

  # Updates the guess state
  updateGuess: ->
    question = @getQuestion()
    firstName = question.firstName
    remainingChars = firstName.length - @guess.length
    starChars = ''
    for i in [0...remainingChars]
      starChars += '*'
    displayName = ucfirst(@guess) + starChars
    @$name.text(displayName)

    # Update description if hard mode
    if @difficulty == 'hard'
      $span = $('<div>').append($('<span>').addClass('name').text(displayName)).html()
      description = question.description.replace(new RegExp(question.firstName, 'g'), $span)
      @$page.find('.person .description').html(description)

  # Returns true if the current guess is correct
  guessIsCorrect: ->
    questionData = @getQuestion()
    return (@guess == questionData.firstName.toLowerCase())

  # Game state
  setGameOverCb: (cb) ->
    @gameOverCb = cb

  # Returns true if the game is over
  gameIsOver: ->
    return @currentQuestionIndex == @questionDataOrder.length

  # Gets the final results of the game
  getResults: ->
    correct = []
    incorrect = []
    for i in [0...@questionDataOrder.length]
      if @correctGuessIndices.indexOf(i) != -1
        correct.push @questionDataOrder[i]
      else
        incorrect.push @questionDataOrder[i]

    results =
      score: @score
      total: @questionDataOrder.length
      correct: correct
      incorrect: incorrect
    return results

module.exports = Game