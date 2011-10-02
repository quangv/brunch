fs = require "fs"
path = require "path"
Walker = require "walker"

{Compiler} = require "./base"


class exports.RequireCompiler extends Compiler
  filePattern: -> [/\.coffee$/]

  checkImports: (file, classes) ->
    coffee = fs.readFileSync file, encoding = "utf8"
    classes.filter (cls) ->
      instantiated = ///new (#{cls.class})[(].*[)]///g
      imported = ///
        #{cls.class}
        [ *]=[ *]
        require
        [('|"]
        (.+)
        ['|").]
        #{cls.class}
      ///g
      instantiated.test coffee and not imported.test coffee

  compile: (files) ->
    endClasses = []
    appPath = path.join @options.brunchPath, "src/app/"
    classRe = /class[ ]+exports.([\\w]+)/g
    # Look for all classes.
    Walker(appPath)
      .on "file", (file) =>
        # only look on coffee files
        return if @filetype(file) isnt "coffee"
        coffee = fs.readFileSync file, encoding="utf8"
        relPath = file.split("/src/app/")[1].split("/")
        directory = ""
        # relative paths and filename for imports
        for element in relPath
          if element isnt relPath[relPath.length-1]
            directory += path.join element, "/"
          else
            file = element.replace ".coffee", ""

        # add all matching classes
        while match = classRe.exec coffee
          endClasses.push {directory, file, class: match[1]}
      .on "end", =>
        # find missing dependencies
        Walker(appPath).on "file", (file) =>
          return if @filetype(file) isnt "coffee"
          missing = @checkImports file, endClasses
          unless @options.require and missing.length > 0
            for cls in missing
              @logError "missing import
                #{path.join(cls.directory, cls.file)}.#{cls.class}"
            return
          # Loop over all missing imports,
          # add to "required" string and alert user.
          required = ""
          for cls in missing
            mPath = path.join cls.directory, cls.file
            @log "adding import #{mPath}"
            required += "app.import #{mPath}, #{cls.class}\n"
          fs.readFile file, (error, data) =>
            return @logError error if error
            # Open file and write import to the beginning of the file.
            data = required + "\n" + data
            fs.writeFile file, data, (error) =>
              return @logError error if error
  
  filetype: (file) ->
    file.split(".").reverse()[0]
