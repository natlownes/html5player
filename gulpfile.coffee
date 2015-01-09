require 'gulp-cjsx'
browserify  = require 'gulp-browserify'
coffee      = require 'gulp-coffee'
coffeeify   = require 'coffeeify'
concat      = require 'gulp-concat'
connect     = require 'connect'
connectjs   = require 'connect-livereload'
gulp        = require 'gulp'
gutil       = require 'gulp-util'
less        = require 'gulp-less'
livereload  = require 'gulp-livereload'
mocha       = require 'gulp-mocha'
serve       = require 'serve-static'


project =
  dest:    './build/'
  dist:    './lib/'
  src:     './src/**/*.coffee'
  static:  './static/**'
  style:   './style/index.less'
  test:    './test/**/*_spec.coffee'


gulp.task 'default', ['build', 'watch']


gulp.task 'build', ['src', 'static', 'style']


gulp.task 'watch:serve', ['watch', 'serve']


gulp.task 'src', ->
  gulp.src(['./src/index.coffee'], read: false)
    .pipe(browserify({
      transform:  [coffeeify]
      extensions: ['.coffee']
    }))
    .pipe(concat('app.js'))
    .pipe(gulp.dest(project.dest))

gulp.task 'dist', ->
  gulp.src('./src/**/*.coffee')
    .pipe(coffee())
    .pipe(gulp.dest(project.dist))


gulp.task 'style', ->
  gulp.src(project.style)
    .pipe(less())
    .pipe(concat('app.css'))
    .pipe(gulp.dest(project.dest))


gulp.task 'static', ->
  gulp.src(project.static)
    .pipe(gulp.dest(project.dest))


gulp.task 'serve', ['build'], ->
  lr  = livereload()
  app = connect()
  app
    .use(connectjs())
    .use(serve(project.dest))
  app.listen(process.env['PORT'] or 4001)
  livereload.listen()
  gulp.watch("#{project.dest}/**").on 'change', (file) ->
    lr.changed(file.path)


gulp.task 'test', ->
  exitOnFinish runTests


gulp.task 'test:watch', ->
  runTests()
  gulp.watch([project.src, project.test], -> runTests())


gulp.task 'watch', ->
  gulp.watch([project.test], -> runTests())
  gulp.watch(project.src, ['src'])
  gulp.watch(project.style, ['style'])
  gulp.watch(project.static, ['static'])


gulp.task 'test:spec', ->
  exitOnFinish runTests, reporter='spec'

runTests = (reporter='dot', bail=true) ->
  gulp.src(project.test, read: false)
    .pipe(mocha(reporter: reporter, bail: bail))
    .on 'error', (err) ->
      gutil.log(err.toString())


exitOnFinish = (func, args...) ->
  func(args...)
    .on 'error', -> process.exit(1)
    .on 'end',   -> process.exit(0)
