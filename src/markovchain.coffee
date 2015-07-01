path = require 'path'

class MarkovChain
  constructor: (options={}) ->
    @sentence_beginning = @_beginning_key = options['beginningToken'] || ''
    @BEGINNING_MARKER = "<BEGSTR>"
    @ENDING_MARKER = "<ENDSTR>"

    @__DEBUG = options['debug'] || false

    @db = options['db'] || {}

  print: (s) ->
    if @__DEBUG then console.log s

  generateChain: (textSample, sentenceSep=/[.!?\n]/) ->
    textSample = textSample.split(sentenceSep)

    sequenceCounts = {}
    probabilities = {}

    for line in textSample
      if line.trim().length < 1 then continue

      words = "#{@BEGINNING_MARKER} #{line.trim()} #{@ENDING_MARKER}".split(" ")

      ngrams = ([words[i], words[i+1]] for i in [0...words.length-1])

      # For each word pair, count the number of times that the second word comes after the first word.
      for pair in ngrams
        if !sequenceCounts[pair[0]]? then sequenceCounts[pair[0]] = {}
        if !sequenceCounts[pair[0]][pair[1]]? then sequenceCounts[pair[0]][pair[1]] = 1
        else
          sequenceCounts[pair[0]][pair[1]]++

      # For each key, calculate the probability of a term coming after it
      for term, followerCounts of sequenceCounts
        nextTerms = (t for t, c of followerCounts when t != @BEGINNING_MARKER)
        denominator = 0
        denominator += c for t, c of followerCounts when t != @BEGINNING_MARKER
        followProbabilities = {}
        followProbabilities[followerTerm] = followerCounts[followerTerm]/denominator for followerTerm in nextTerms
        if term == @BEGINNING_MARKER then followProbabilities[@BEGINNING_MARKER] = 0.0
        probabilities[term] = followProbabilities

    @db = probabilities
    @db

  dump: () ->
    return JSON.stringify(@db)

  load: (dbJson) ->
    @db = JSON.parse(dbJson)

  __getNextWord: (lastwords) ->
    lastTerm = lastwords.slice(-1)
    probmap = @db[lastTerm]
    sample = Math.random()
    maxprob = 0.0
    maxprobword = ""
    for candidate of probmap
      if probmap[candidate] > maxprob
        @print "#{probmap[candidate]} > #{maxprob}"
        maxprob = probmap[candidate]
        maxprobword = candidate
      if sample > probmap[candidate]
        sample -= probmap[candidate]
      else
        return candidate

    return maxprobword

  __generateFromState: (words) ->
    nextword = @__getNextWord(words)
    sentence = if words? then words else []

    while nextword != @ENDING_MARKER
      sentence.push(nextword)
      nextword = @__getNextWord(sentence)

    return sentence.join(" ").replace(@BEGINNING_MARKER, @_beginning_key).trim()

  generateString: () -> @__generateFromState([@BEGINNING_MARKER])

module.exports = MarkovChain