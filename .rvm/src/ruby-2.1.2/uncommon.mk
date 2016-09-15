bin: $(PROGRAM) $(WPROGRAM)
lib: $(LIBRUBY)
dll: $(LIBRUBY_SO)

.SUFFIXES: .inc .h .c .y .i .$(DTRACE_EXT)

# V=0 quiet, V=1 verbose.  other values don't work.
V = 0
Q1 = $(V:1=)
Q = $(Q1:0=@)
ECHO = $(ECHO1:0=@echo)

RUBYLIB       = $(PATH_SEPARATOR)
RUBYOPT       = -
RUN_OPTS      = --disable-gems

SPEC_GIT_BASE = git://github.com/nurse
MSPEC_GIT_URL = $(SPEC_GIT_BASE)/mspec.git
RUBYSPEC_GIT_URL = $(SPEC_GIT_BASE)/rubyspec.git

STATIC_RUBY   = static-ruby

EXTCONF       = extconf.rb
LIBRUBY_EXTS  = ./.libruby-with-ext.time
REVISION_H    = ./.revision.time
PLATFORM_D    = ./$(PLATFORM_DIR)/.time
RDOCOUT       = $(EXTOUT)/rdoc
CAPIOUT       = doc/capi

DMYEXT	      = dmyext.$(OBJEXT)
NORMALMAINOBJ = main.$(OBJEXT)
MAINOBJ       = $(NORMALMAINOBJ)
EXTOBJS	      =
DLDOBJS	      = $(DMYEXT)
EXTSOLIBS     =
MINIOBJS      = $(ARCHMINIOBJS) miniinit.$(OBJEXT) miniprelude.$(OBJEXT)
ENC_MK        = enc.mk

COMMONOBJS    = array.$(OBJEXT) \
		bignum.$(OBJEXT) \
		class.$(OBJEXT) \
		compar.$(OBJEXT) \
		complex.$(OBJEXT) \
		dir.$(OBJEXT) \
		dln_find.$(OBJEXT) \
		encoding.$(OBJEXT) \
		enum.$(OBJEXT) \
		enumerator.$(OBJEXT) \
		error.$(OBJEXT) \
		eval.$(OBJEXT) \
		load.$(OBJEXT) \
		proc.$(OBJEXT) \
		file.$(OBJEXT) \
		gc.$(OBJEXT) \
		hash.$(OBJEXT) \
		inits.$(OBJEXT) \
		io.$(OBJEXT) \
		marshal.$(OBJEXT) \
		math.$(OBJEXT) \
		node.$(OBJEXT) \
		numeric.$(OBJEXT) \
		object.$(OBJEXT) \
		pack.$(OBJEXT) \
		parse.$(OBJEXT) \
		process.$(OBJEXT) \
		random.$(OBJEXT) \
		range.$(OBJEXT) \
		rational.$(OBJEXT) \
		re.$(OBJEXT) \
		regcomp.$(OBJEXT) \
		regenc.$(OBJEXT) \
		regerror.$(OBJEXT) \
		regexec.$(OBJEXT) \
		regparse.$(OBJEXT) \
		regsyntax.$(OBJEXT) \
		ruby.$(OBJEXT) \
		safe.$(OBJEXT) \
		signal.$(OBJEXT) \
		sprintf.$(OBJEXT) \
		st.$(OBJEXT) \
		strftime.$(OBJEXT) \
		string.$(OBJEXT) \
		struct.$(OBJEXT) \
		time.$(OBJEXT) \
		transcode.$(OBJEXT) \
		util.$(OBJEXT) \
		variable.$(OBJEXT) \
		version.$(OBJEXT) \
		compile.$(OBJEXT) \
		debug.$(OBJEXT) \
		iseq.$(OBJEXT) \
		vm.$(OBJEXT) \
		vm_dump.$(OBJEXT) \
		vm_backtrace.$(OBJEXT) \
		vm_trace.$(OBJEXT) \
		thread.$(OBJEXT) \
		cont.$(OBJEXT) \
		$(BUILTIN_ENCOBJS) \
		$(BUILTIN_TRANSOBJS) \
		$(MISSING)

EXPORTOBJS    = $(DLNOBJ) \
		localeinit.$(OBJEXT) \
		loadpath.$(OBJEXT) \
		$(COMMONOBJS)

OBJS          = $(EXPORTOBJS) prelude.$(OBJEXT)
ALLOBJS       = $(NORMALMAINOBJ) $(MINIOBJS) $(COMMONOBJS) $(DMYEXT)

GOLFOBJS      = goruby.$(OBJEXT) golf_prelude.$(OBJEXT)

PRELUDE_SCRIPTS = $(srcdir)/prelude.rb $(srcdir)/enc/prelude.rb $(DEFAULT_PRELUDES)
GEM_PRELUDE = $(srcdir)/gem_prelude.rb
PRELUDES      = prelude.c miniprelude.c
GOLFPRELUDES = golf_prelude.c

SCRIPT_ARGS   =	--dest-dir="$(DESTDIR)" \
		--extout="$(EXTOUT)" \
		--mflags="$(MFLAGS)" \
		--make-flags="$(MAKEFLAGS)"
EXTMK_ARGS    =	$(SCRIPT_ARGS) --extension $(EXTS) --extstatic $(EXTSTATIC) \
		--make-flags="V=$(V) MINIRUBY='$(MINIRUBY)'" --
INSTRUBY      =	$(SUDO) $(RUNRUBY) -r./$(arch)-fake $(srcdir)/tool/rbinstall.rb
INSTRUBY_ARGS =	$(SCRIPT_ARGS) \
		--data-mode=$(INSTALL_DATA_MODE) \
		--prog-mode=$(INSTALL_PROG_MODE) \
		--installed-list $(INSTALLED_LIST) \
		--mantype="$(MANTYPE)"
INSTALL_PROG_MODE = 0755
INSTALL_DATA_MODE = 0644

PRE_LIBRUBY_UPDATE = $(MINIRUBY) -e 'ARGV[1] or File.unlink(ARGV[0]) rescue nil' -- \
			$(LIBRUBY_EXTS) $(LIBRUBY_SO_UPDATE)

TESTSDIR      = $(srcdir)/test
TESTWORKDIR   = testwork

TESTRUN_SCRIPT = $(srcdir)/test.rb

BOOTSTRAPRUBY = $(BASERUBY)

COMPILE_PRELUDE = $(MINIRUBY) -I$(srcdir) $(srcdir)/tool/compile_prelude.rb

all: showflags main docs

main: showflags $(EXTSTATIC:static=lib)encs exts
	@$(NULLCMD)

.PHONY: showflags
exts enc trans: showflags
showflags:
	$(MESSAGE_BEGIN) \
	"	CC = $(CC)" \
	"	LD = $(LD)" \
	"	LDSHARED = $(LDSHARED)" \
	"	CFLAGS = $(CFLAGS)" \
	"	XCFLAGS = $(XCFLAGS)" \
	"	CPPFLAGS = $(CPPFLAGS)" \
	"	DLDFLAGS = $(DLDFLAGS)" \
	"	SOLIBS = $(SOLIBS)" \
	$(MESSAGE_END)
	-@$(CC_VERSION)

.PHONY: showconfig
showconfig:
	@$(ECHO_BEGIN) \
	$(configure_args) \
	$(ECHO_END)

exts: build-ext

EXTS_MK = exts.mk
$(EXTS_MK): $(MKFILES) all-incs $(PREP) $(RBCONFIG) $(LIBRUBY)
	$(ECHO) generating makefile $@
	$(Q)$(MINIRUBY) $(srcdir)/ext/extmk.rb --make="$(MAKE)" --command-output=$(EXTS_MK) $(EXTMK_ARGS) configure

configure-ext: $(EXTS_MK)

build-ext: $(EXTS_MK)
	$(Q)$(MAKE) -f $(EXTS_MK) $(MFLAGS) $(EXTSTATIC) LIBRUBY_EXTS=$(LIBRUBY_EXTS) ENCOBJS="$(ENCOBJS)"

$(MKMAIN_CMD): $(MKFILES) all-incs $(PREP) $(RBCONFIG) $(LIBRUBY)
	$(Q)$(MINIRUBY) $(srcdir)/ext/extmk.rb --make="$(MAKE)" --command-output=$@ $(EXTMK_ARGS)

prog: program wprogram

$(PREP): $(MKFILES)

miniruby$(EXEEXT): config.status $(ALLOBJS) $(ARCHFILE) $(DTRACE_OBJ)

objs: $(ALLOBJS)

GORUBY = go$(RUBY_INSTALL_NAME)
golf: $(LIBRUBY) $(GOLFOBJS) PHONY
	$(Q) $(MAKE) $(MFLAGS) MAINOBJ="$(GOLFOBJS)" PROGRAM=$(GORUBY)$(EXEEXT) program
capi: $(CAPIOUT)/.timestamp PHONY

$(CAPIOUT)/.timestamp: Doxyfile $(PREP)
	$(Q) $(MAKEDIRS) "$(@D)"
	$(ECHO) generating capi
	$(Q) $(DOXYGEN) -b
	$(Q) $(MINIRUBY) -e 'File.open(ARGV[0], "w"){|f| f.puts(Time.now)}' "$@"

Doxyfile: $(srcdir)/template/Doxyfile.tmpl $(PREP) $(srcdir)/tool/generic_erb.rb $(RBCONFIG)
	$(ECHO) generating $@
	$(Q) $(MINIRUBY) $(srcdir)/tool/generic_erb.rb -o $@ $(srcdir)/template/Doxyfile.tmpl \
	--srcdir="$(srcdir)" --miniruby="$(BASERUBY)"

program: showflags $(PROGRAM)
wprogram: showflags $(WPROGRAM)
mini: PHONY miniruby$(EXEEXT)

$(PROGRAM) $(WPROGRAM): $(LIBRUBY) $(MAINOBJ) $(OBJS) $(EXTOBJS) $(SETUP) $(PREP)

$(LIBRUBY_A):	$(OBJS) $(MAINOBJ) $(DTRACE_OBJ) $(DTRACE_GLOMMED_OBJ) $(DMYEXT) $(ARCHFILE)

$(LIBRUBY_SO):	$(OBJS) $(DLDOBJS) $(LIBRUBY_A) $(PREP) $(LIBRUBY_SO_UPDATE) $(BUILTIN_ENCOBJS)

$(LIBRUBY_EXTS):
	@exit > $@

$(STATIC_RUBY)$(EXEEXT): $(MAINOBJ) $(DLDOBJS) $(EXTOBJS) $(LIBRUBY_A)
	$(Q)$(RM) $@
	$(PURIFY) $(CC) $(MAINOBJ) $(DLDOBJS) $(EXTOBJS) $(LIBRUBY_A) $(MAINLIBS) $(EXTLIBS) $(LIBS) $(OUTFLAG)$@ $(LDFLAGS) $(XLDFLAGS)

ruby.imp: $(COMMONOBJS)
	$(Q)$(NM) -Pgp $(COMMONOBJS) | \
	awk 'BEGIN{print "#!"}; $$2~/^[BDT]$$/&&$$1!~/^(Init_|.*_threadptr_|\.)/{print $$1}' | \
	sort -u -o $@

install: install-$(INSTALLDOC)
docs: $(DOCTARGETS)
pkgconfig-data: $(ruby_pc)
$(ruby_pc): $(srcdir)/template/ruby.pc.in config.status

install-all: docs pre-install-all do-install-all post-install-all
pre-install-all:: pre-install-local pre-install-ext pre-install-doc
do-install-all: all
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=all --rdoc-output="$(RDOCOUT)"
post-install-all:: post-install-local post-install-ext post-install-doc
	@$(NULLCMD)

install-nodoc: pre-install-nodoc do-install-nodoc post-install-nodoc
pre-install-nodoc:: pre-install-local pre-install-ext
do-install-nodoc: main
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS)
post-install-nodoc:: post-install-local post-install-ext

install-local: pre-install-local do-install-local post-install-local
pre-install-local:: pre-install-bin pre-install-lib pre-install-man
do-install-local: $(PROGRAM)
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=local
post-install-local:: post-install-bin post-install-lib post-install-man

install-ext: pre-install-ext do-install-ext post-install-ext
pre-install-ext:: pre-install-ext-arch pre-install-ext-comm
do-install-ext: exts
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=ext
post-install-ext:: post-install-ext-arch post-install-ext-comm

install-arch: pre-install-arch do-install-arch post-install-arch
pre-install-arch:: pre-install-bin pre-install-ext-arch
do-install-arch: main
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=arch
post-install-arch:: post-install-bin post-install-ext-arch

install-comm: pre-install-comm do-install-comm post-install-comm
pre-install-comm:: pre-install-lib pre-install-ext-comm pre-install-man
do-install-comm: $(PREP)
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=lib --install=ext-comm --install=man
post-install-comm:: post-install-lib post-install-ext-comm post-install-man

install-bin: pre-install-bin do-install-bin post-install-bin
pre-install-bin:: install-prereq
do-install-bin: $(PROGRAM)
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=bin
post-install-bin::
	@$(NULLCMD)

install-lib: pre-install-lib do-install-lib post-install-lib
pre-install-lib:: install-prereq
do-install-lib: $(PREP)
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=lib
post-install-lib::
	@$(NULLCMD)

install-ext-comm: pre-install-ext-comm do-install-ext-comm post-install-ext-comm
pre-install-ext-comm:: install-prereq
do-install-ext-comm: exts
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=ext-comm
post-install-ext-comm::
	@$(NULLCMD)

install-ext-arch: pre-install-ext-arch do-install-ext-arch post-install-ext-arch
pre-install-ext-arch:: install-prereq
do-install-ext-arch: exts
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=ext-arch
post-install-ext-arch::
	@$(NULLCMD)

install-man: pre-install-man do-install-man post-install-man
pre-install-man:: install-prereq
do-install-man: $(PREP)
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=man
post-install-man::
	@$(NULLCMD)

install-capi: capi pre-install-capi do-install-capi post-install-capi
pre-install-capi:: install-prereq
do-install-capi: $(PREP)
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=capi
post-install-capi::
	@$(NULLCMD)

what-where: no-install
no-install: no-install-$(INSTALLDOC)
what-where-all: no-install-all
no-install-all: pre-no-install-all dont-install-all post-no-install-all
pre-no-install-all:: pre-no-install-local pre-no-install-ext pre-no-install-doc
dont-install-all: $(PROGRAM)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=all --rdoc-output="$(RDOCOUT)"
post-no-install-all:: post-no-install-local post-no-install-ext post-no-install-doc
	@$(NULLCMD)

uninstall: $(INSTALLED_LIST)
	$(Q)$(SUDO) $(MINIRUBY) $(srcdir)/tool/rbuninstall.rb --destdir=$(DESTDIR) $(INSTALLED_LIST)

reinstall: uninstall install

what-where-nodoc: no-install-nodoc
no-install-nodoc: pre-no-install-nodoc dont-install-nodoc post-no-install-nodoc
pre-no-install-nodoc:: pre-no-install-local pre-no-install-ext
dont-install-nodoc:  $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS)
post-no-install-nodoc:: post-no-install-local post-no-install-ext

what-where-local: no-install-local
no-install-local: pre-no-install-local dont-install-local post-no-install-local
pre-no-install-local:: pre-no-install-bin pre-no-install-lib pre-no-install-man
dont-install-local: $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=local
post-no-install-local:: post-no-install-bin post-no-install-lib post-no-install-man

what-where-ext: no-install-ext
no-install-ext: pre-no-install-ext dont-install-ext post-no-install-ext
pre-no-install-ext:: pre-no-install-ext-arch pre-no-install-ext-comm
dont-install-ext: $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=ext
post-no-install-ext:: post-no-install-ext-arch post-no-install-ext-comm

what-where-arch: no-install-arch
no-install-arch: pre-no-install-arch dont-install-arch post-no-install-arch
pre-no-install-arch:: pre-no-install-bin pre-no-install-ext-arch
dont-install-arch: $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=bin --install=ext-arch
post-no-install-arch:: post-no-install-lib post-no-install-man post-no-install-ext-arch

what-where-comm: no-install-comm
no-install-comm: pre-no-install-comm dont-install-comm post-no-install-comm
pre-no-install-comm:: pre-no-install-lib pre-no-install-ext-comm pre-no-install-man
dont-install-comm: $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=lib --install=ext-comm --install=man
post-no-install-comm:: post-no-install-lib post-no-install-ext-comm post-no-install-man

what-where-bin: no-install-bin
no-install-bin: pre-no-install-bin dont-install-bin post-no-install-bin
pre-no-install-bin:: install-prereq
dont-install-bin: $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=bin
post-no-install-bin::
	@$(NULLCMD)

what-where-lib: no-install-lib
no-install-lib: pre-no-install-lib dont-install-lib post-no-install-lib
pre-no-install-lib:: install-prereq
dont-install-lib: $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=lib
post-no-install-lib::
	@$(NULLCMD)

what-where-ext-comm: no-install-ext-comm
no-install-ext-comm: pre-no-install-ext-comm dont-install-ext-comm post-no-install-ext-comm
pre-no-install-ext-comm:: install-prereq
dont-install-ext-comm: $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=ext-comm
post-no-install-ext-comm::
	@$(NULLCMD)

what-where-ext-arch: no-install-ext-arch
no-install-ext-arch: pre-no-install-ext-arch dont-install-ext-arch post-no-install-ext-arch
pre-no-install-ext-arch:: install-prereq
dont-install-ext-arch: $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=ext-arch
post-no-install-ext-arch::
	@$(NULLCMD)

what-where-man: no-install-man
no-install-man: pre-no-install-man dont-install-man post-no-install-man
pre-no-install-man:: install-prereq
dont-install-man: $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=man
post-no-install-man::
	@$(NULLCMD)

install-doc: rdoc pre-install-doc do-install-doc post-install-doc
pre-install-doc:: install-prereq
do-install-doc: $(PROGRAM)
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=rdoc --rdoc-output="$(RDOCOUT)"
post-install-doc::
	@$(NULLCMD)

install-gem: pre-install-gem do-install-gem post-install-gem
pre-install-gem:: pre-install-bin pre-install-lib pre-install-man
do-install-gem: $(PROGRAM)
	$(INSTRUBY) --make="$(MAKE)" $(INSTRUBY_ARGS) --install=gem
post-install-gem::
	@$(NULLCMD)

rdoc: PHONY main
	@echo Generating RDoc documentation
	$(Q) $(XRUBY) "$(srcdir)/bin/rdoc" --root "$(srcdir)" --page-dir "$(srcdir)/doc" --encoding=UTF-8 --no-force-update --all --ri --op "$(RDOCOUT)" --debug $(RDOCFLAGS) "$(srcdir)"

rdoc-coverage: PHONY main
	@echo Generating RDoc coverage report
	$(Q) $(XRUBY) "$(srcdir)/bin/rdoc" --root "$(srcdir)" --encoding=UTF-8 --all --quiet -C $(RDOCFLAGS) "$(srcdir)"

RDOCBENCHOUT=/tmp/rdocbench

GCBENCH_ITEM=null

gcbench: PHONY
	$(Q) $(XRUBY) "$(srcdir)/benchmark/gc/gcbench.rb" $(GCBENCH_ITEM)

gcbench-rdoc: PHONY
	$(Q) $(XRUBY) "$(srcdir)/benchmark/gc/gcbench.rb" rdoc

nodoc: PHONY

what-where-doc: no-install-doc
no-install-doc: pre-no-install-doc dont-install-doc post-no-install-doc
pre-no-install-doc:: install-prereq
dont-install-doc:: $(PREP)
	$(INSTRUBY) -n --make="$(MAKE)" $(INSTRUBY_ARGS) --install=rdoc --rdoc-output="$(RDOCOUT)"
post-no-install-doc::
	@$(NULLCMD)

CLEAR_INSTALLED_LIST = clear-installed-list

install-prereq: $(CLEAR_INSTALLED_LIST) yes-fake PHONY

clear-installed-list: PHONY
	@> $(INSTALLED_LIST) set MAKE="$(MAKE)"

clean: clean-ext clean-local clean-enc clean-golf clean-rdoc clean-capi clean-extout clean-platform
clean-local:: PHONY
	$(Q)$(RM) $(OBJS) $(MINIOBJS) $(MAINOBJ) $(LIBRUBY_A) $(LIBRUBY_SO) $(LIBRUBY) $(LIBRUBY_ALIASES)
	$(Q)$(RM) $(PROGRAM) $(WPROGRAM) miniruby$(EXEEXT) dmyext.$(OBJEXT) $(ARCHFILE) .*.time
	$(Q)$(RM) y.tab.c y.output encdb.h transdb.h prelude.c config.log rbconfig.rb $(ruby_pc) probes.h probes.$(OBJEXT) probes.stamp ruby-glommed.$(OBJEXT)
clean-ext:: PHONY
clean-golf: PHONY
	$(Q)$(RM) $(GORUBY)$(EXEEXT) $(GOLFOBJS)
clean-rdoc: PHONY
clean-capi: PHONY
clean-platform: PHONY
clean-extout: PHONY
clean-docs: clean-rdoc clean-capi

distclean: distclean-ext distclean-local distclean-enc distclean-golf distclean-extout distclean-platform
distclean-local:: clean-local
	$(Q)$(RM) $(MKFILES) yasmdata.rb *.inc
	$(Q)$(RM) config.cache config.status config.status.lineno
	$(Q)$(RM) *~ *.bak *.stackdump core *.core gmon.out $(PREP)
distclean-ext:: PHONY
distclean-golf: clean-golf
	$(Q)$(RM) $(GOLFPRELUDES)
distclean-rdoc: PHONY
distclean-capi: PHONY
distclean-extout: clean-extout
distclean-platform: clean-platform

realclean:: realclean-ext realclean-local realclean-enc realclean-golf realclean-extout
realclean-local:: distclean-local
	$(Q)$(RM) parse.c parse.h lex.c newline.c miniprelude.c revision.h
realclean-ext:: PHONY
realclean-golf: distclean-golf
realclean-capi: PHONY
realclean-extout: distclean-extout

clean-ext distclean-ext realclean-ext::
	$(Q)$(RM) $(EXTS_MK)
	$(Q)$(RM) $(EXTOUT)/.timestamp/.*.time

clean-enc distclean-enc realclean-enc: PHONY

check: main test test-all
	$(ECHO) check succeeded
check-ruby: test test-ruby

fake: $(CROSS_COMPILING)-fake
yes-fake: $(arch)-fake.rb $(RBCONFIG) PHONY
no-fake: PHONY

btest: $(TEST_RUNNABLE)-btest
no-btest: PHONY
yes-btest: fake miniruby$(EXEEXT) PHONY
	$(BOOTSTRAPRUBY) "$(srcdir)/bootstraptest/runner.rb" --ruby="$(BTESTRUBY) $(RUN_OPTS)" $(OPTS) $(TESTOPTS)

btest-ruby: $(TEST_RUNNABLE)-btest-ruby
no-btest-ruby: PHONY
yes-btest-ruby: prog PHONY
	$(Q)$(RUNRUBY) "$(srcdir)/bootstraptest/runner.rb" --ruby="$(PROGRAM) -I$(srcdir)/lib $(RUN_OPTS)" -q $(OPTS) $(TESTOPTS)

test-sample: $(TEST_RUNNABLE)-test-sample
no-test-sample: PHONY
yes-test-sample: prog PHONY
	$(Q)$(RUNRUBY) $(srcdir)/tool/rubytest.rb --run-opt=$(RUN_OPTS) $(OPTS) $(TESTOPTS)

test-knownbugs: test-knownbug
test-knownbug: $(TEST_RUNNABLE)-test-knownbug
no-test-knownbug: PHONY
yes-test-knownbug: prog PHONY
	-$(RUNRUBY) "$(srcdir)/bootstraptest/runner.rb" --ruby="$(PROGRAM) $(RUN_OPTS)" $(OPTS) $(TESTOPTS) $(srcdir)/KNOWNBUGS.rb

test: test-sample btest-ruby test-knownbug

test-all: $(TEST_RUNNABLE)-test-all
yes-test-all: prog PHONY
	$(RUNRUBY) "$(srcdir)/test/runner.rb" --ruby="$(RUNRUBY)" $(TESTOPTS) $(TESTS)
TESTS_BUILD = mkmf
no-test-all: PHONY
	$(MINIRUBY) -I"$(srcdir)/lib" "$(srcdir)/test/runner.rb" $(TESTOPTS) $(TESTS_BUILD)

test-ruby: $(TEST_RUNNABLE)-test-ruby
no-test-ruby: PHONY
yes-test-ruby: prog encs PHONY
	$(RUNRUBY) "$(srcdir)/test/runner.rb" -q $(TESTOPTS) -- ruby -ext-

extconf: $(PREP)
	$(Q) $(MAKEDIRS) "$(EXTCONFDIR)"
	$(RUNRUBY) -C "$(EXTCONFDIR)" $(EXTCONF) $(EXTCONFARGS)

$(RBCONFIG): $(srcdir)/tool/mkconfig.rb config.status $(srcdir)/version.h $(PREP)
	$(Q)$(MINIRUBY) $(srcdir)/tool/mkconfig.rb -timestamp=$@ \
		-install_name=$(RUBY_INSTALL_NAME) \
		-so_name=$(RUBY_SO_NAME) rbconfig.rb

test-rubyspec-precheck:

test-rubyspec: test-rubyspec-precheck
	$(RUNRUBY) $(srcdir)/spec/mspec/bin/mspec run -B $(srcdir)/spec/default.mspec $(MSPECOPT)

RUNNABLE = $(LIBRUBY_RELATIVE:no=un)-runnable
runnable: $(RUNNABLE) prog $(srcdir)/tool/mkrunnable.rb PHONY
	$(Q) $(MINIRUBY) $(srcdir)/tool/mkrunnable.rb -v $(EXTOUT)
yes-runnable: PHONY

encs: enc trans
libencs: libenc libtrans
encs enc trans libencs libenc libtrans: showflags $(ENC_MK) $(LIBRUBY) $(PREP)
	$(ECHO) making $@
	$(Q) $(MAKE) -f $(ENC_MK) V="$(V)" \
		RUBY="$(MINIRUBY)" MINIRUBY="$(MINIRUBY)" \
		$(MFLAGS) $@


libenc enc: encdb.h
libtrans trans: transdb.h

$(ENC_MK): $(srcdir)/enc/make_encmake.rb $(srcdir)/enc/Makefile.in $(srcdir)/enc/depend \
	$(srcdir)/enc/encinit.c.erb $(srcdir)/lib/mkmf.rb $(RBCONFIG)
	$(ECHO) generating $@
	$(Q) $(MINIRUBY) $(srcdir)/enc/make_encmake.rb --builtin-encs="$(BUILTIN_ENCOBJS)" --builtin-transes="$(BUILTIN_TRANSOBJS)" --module$(EXTSTATIC) $@ $(ENCS)

.PRECIOUS: $(MKFILES)

.PHONY: PHONY all fake prereq incs srcs preludes help
.PHONY: test install install-nodoc install-doc dist
.PHONY: loadpath golf capi rdoc install-prereq clear-installed-list
.PHONY: clean clean-ext clean-local clean-enc clean-golf clean-rdoc clean-extout
.PHONY: distclean distclean-ext distclean-local distclean-enc distclean-golf distclean-extout
.PHONY: realclean realclean-ext realclean-local realclean-enc realclean-golf realclean-extout
.PHONY: check test test-all btest btest-ruby test-sample test-knownbug
.PHONY: run runruby parse benchmark benchmark-each tbench gdb gdb-ruby
.PHONY: update-mspec update-rubyspec test-rubyspec

PHONY:

parse.c: parse.y $(srcdir)/tool/ytab.sed id.h
parse.h: parse.c

.y.c:
	$(ECHO) generating $@
	$(Q)$(BASERUBY) $(srcdir)/tool/id2token.rb --path-separator=.$(PATH_SEPARATOR)./ --vpath=$(VPATH) id.h $(SRC_FILE) > parse.tmp.y
	$(Q)$(YACC) -d $(YFLAGS) -o y.tab.c parse.tmp.y
	$(Q)$(RM) parse.tmp.y
	$(Q)sed -f $(srcdir)/tool/ytab.sed -e "/^#/s!parse\.tmp\.[iy]!parse.y!" -e "/^#/s!y\.tab\.c!$@!" y.tab.c > $@.new
	$(Q)$(MV) $@.new $@
	$(Q)sed -e "/^#line.*y\.tab\.h/d;/^#line.*parse.*\.y/d" y.tab.h > $(@:.c=.h)
	$(Q)$(RM) y.tab.c y.tab.h

$(PLATFORM_D):
	$(Q) $(MAKEDIRS) $(PLATFORM_DIR)
	@exit > $@

###

RUBY_H_INCLUDES    = ruby.h config.h defines.h \
		     intern.h missing.h st.h \
		     subst.h
ENCODING_H_INCLUDES= encoding.h oniguruma.h
PROBES_H_INCLUDES  = probes.h
VM_CORE_H_INCLUDES = vm_core.h thread_$(THREAD_MODEL).h \
		     node.h method.h ruby_atomic.h \
	             vm_debug.h id.h thread_native.h

###

acosh.$(OBJEXT): acosh.c
alloca.$(OBJEXT): alloca.c config.h
crypt.$(OBJEXT): crypt.c
dup2.$(OBJEXT): dup2.c
erf.$(OBJEXT): erf.c
finite.$(OBJEXT): finite.c
flock.$(OBJEXT): flock.c
memcmp.$(OBJEXT): memcmp.c
memmove.$(OBJEXT): memmove.c
mkdir.$(OBJEXT): mkdir.c
setproctitle.$(OBJEXT): setproctitle.c util.h $(RUBY_H_INCLUDES) $(hdrdir)/ruby.h
strchr.$(OBJEXT): strchr.c
strdup.$(OBJEXT): strdup.c
strerror.$(OBJEXT): strerror.c
strlcat.$(OBJEXT): strlcat.c
strlcpy.$(OBJEXT): strlcpy.c
strstr.$(OBJEXT): strstr.c
strtod.$(OBJEXT): strtod.c
strtol.$(OBJEXT): strtol.c
nt.$(OBJEXT): nt.c
os2.$(OBJEXT): os2.c
dl_os2.$(OBJEXT): dl_os2.c
ia64.$(OBJEXT): ia64.s
	$(CC) $(CFLAGS) -c $<

###

addr2line.$(OBJEXT): addr2line.c addr2line.h config.h
array.$(OBJEXT): array.c $(RUBY_H_INCLUDES) util.h \
  $(ENCODING_H_INCLUDES) internal.h $(PROBES_H_INCLUDES) id.h vm_opts.h
bignum.$(OBJEXT): bignum.c $(RUBY_H_INCLUDES) util.h \
  thread.h internal.h
class.$(OBJEXT): class.c $(RUBY_H_INCLUDES) \
  $(VM_CORE_H_INCLUDES) internal.h constant.h vm_opts.h
compar.$(OBJEXT): compar.c $(RUBY_H_INCLUDES)
complex.$(OBJEXT): complex.c $(RUBY_H_INCLUDES) \
  internal.h $(hdrdir)/ruby.h
dir.$(OBJEXT): dir.c $(RUBY_H_INCLUDES) util.h \
  $(ENCODING_H_INCLUDES) \
  internal.h
dln.$(OBJEXT): dln.c dln.h $(RUBY_H_INCLUDES)
dln_find.$(OBJEXT): dln_find.c dln.h $(RUBY_H_INCLUDES)
dmydln.$(OBJEXT): dmydln.c $(RUBY_H_INCLUDES)
dmyext.$(OBJEXT): dmyext.c
encoding.$(OBJEXT): encoding.c $(RUBY_H_INCLUDES) \
  $(ENCODING_H_INCLUDES) regenc.h util.h \
  internal.h
enum.$(OBJEXT): enum.c $(RUBY_H_INCLUDES) node.h \
  util.h id.h internal.h
enumerator.$(OBJEXT): enumerator.c $(RUBY_H_INCLUDES) \
  internal.h node.h
error.$(OBJEXT): error.c known_errors.inc \
  $(RUBY_H_INCLUDES) $(VM_CORE_H_INCLUDES) $(ENCODING_H_INCLUDES) \
  internal.h vm_opts.h
eval.$(OBJEXT): eval.c eval_intern.h vm.h \
  $(RUBY_H_INCLUDES) $(VM_CORE_H_INCLUDES) eval_error.c \
  eval_jump.c gc.h iseq.h \
  $(ENCODING_H_INCLUDES) internal.h $(PROBES_H_INCLUDES) vm_opts.h probes_helper.h
load.$(OBJEXT): load.c eval_intern.h \
  util.h $(RUBY_H_INCLUDES) $(VM_CORE_H_INCLUDES) \
  dln.h internal.h $(PROBES_H_INCLUDES) vm_opts.h
file.$(OBJEXT): file.c $(RUBY_H_INCLUDES) io.h \
  $(ENCODING_H_INCLUDES) util.h dln.h \
  internal.h
gc.$(OBJEXT): gc.c $(RUBY_H_INCLUDES) re.h \
  regex.h $(ENCODING_H_INCLUDES) $(VM_CORE_H_INCLUDES) \
  gc.h io.h eval_intern.h util.h \
  internal.h constant.h \
  thread.h $(PROBES_H_INCLUDES) vm_opts.h debug.h
hash.$(OBJEXT): hash.c $(RUBY_H_INCLUDES) util.h \
  $(ENCODING_H_INCLUDES) internal.h $(PROBES_H_INCLUDES) vm_opts.h
inits.$(OBJEXT): inits.c $(RUBY_H_INCLUDES) \
  internal.h
io.$(OBJEXT): io.c $(RUBY_H_INCLUDES) io.h \
  util.h $(ENCODING_H_INCLUDES) dln.h \
  internal.h thread.h id.h ruby_atomic.h
main.$(OBJEXT): main.c $(RUBY_H_INCLUDES) node.h vm_debug.h vm_opts.h $(hdrdir)/ruby.h
marshal.$(OBJEXT): marshal.c $(RUBY_H_INCLUDES) io.h \
  $(ENCODING_H_INCLUDES) util.h internal.h
math.$(OBJEXT): math.c $(RUBY_H_INCLUDES) \
  internal.h
node.$(OBJEXT): node.c $(RUBY_H_INCLUDES) \
  $(VM_CORE_H_INCLUDES) vm_opts.h internal.h
numeric.$(OBJEXT): numeric.c $(RUBY_H_INCLUDES) \
  util.h $(ENCODING_H_INCLUDES) internal.h id.h
object.$(OBJEXT): object.c $(RUBY_H_INCLUDES) util.h \
  internal.h constant.h $(ENCODING_H_INCLUDES) $(PROBES_H_INCLUDES) \
  vm_opts.h id.h
pack.$(OBJEXT): pack.c $(RUBY_H_INCLUDES) encoding.h \
  oniguruma.h internal.h
parse.$(OBJEXT): parse.c $(RUBY_H_INCLUDES) node.h \
  $(ENCODING_H_INCLUDES) id.h regenc.h \
  regex.h util.h lex.c \
  defs/keywords id.c parse.y \
  parse.h internal.h $(PROBES_H_INCLUDES) vm_opts.h
proc.$(OBJEXT): proc.c eval_intern.h \
  $(RUBY_H_INCLUDES) gc.h $(VM_CORE_H_INCLUDES) \
  internal.h iseq.h vm_opts.h
process.$(OBJEXT): process.c $(RUBY_H_INCLUDES) \
  util.h io.h $(ENCODING_H_INCLUDES) dln.h \
  $(VM_CORE_H_INCLUDES) internal.h \
  thread.h vm_opts.h
random.$(OBJEXT): random.c $(RUBY_H_INCLUDES) \
  siphash.c siphash.h internal.h
range.$(OBJEXT): range.c $(RUBY_H_INCLUDES) \
  $(ENCODING_H_INCLUDES) internal.h id.h
rational.$(OBJEXT): rational.c $(RUBY_H_INCLUDES) internal.h $(hdrdir)/ruby.h
re.$(OBJEXT): re.c $(RUBY_H_INCLUDES) re.h \
  regex.h $(ENCODING_H_INCLUDES) util.h \
  regint.h regenc.h internal.h
regcomp.$(OBJEXT): regcomp.c regparse.h \
  regint.h regenc.h oniguruma.h \
  $(RUBY_H_INCLUDES)
regenc.$(OBJEXT): regenc.c regint.h \
  regenc.h oniguruma.h $(RUBY_H_INCLUDES)
regerror.$(OBJEXT): regerror.c regint.h \
  regenc.h oniguruma.h $(RUBY_H_INCLUDES)
regexec.$(OBJEXT): regexec.c regint.h \
  regenc.h oniguruma.h $(RUBY_H_INCLUDES)
regparse.$(OBJEXT): regparse.c regparse.h \
  regint.h regenc.h oniguruma.h \
  $(RUBY_H_INCLUDES)
regsyntax.$(OBJEXT): regsyntax.c regint.h \
  regenc.h oniguruma.h $(RUBY_H_INCLUDES)
ruby.$(OBJEXT): ruby.c $(RUBY_H_INCLUDES) util.h \
  $(ENCODING_H_INCLUDES) eval_intern.h $(VM_CORE_H_INCLUDES) \
  dln.h internal.h vm_opts.h
safe.$(OBJEXT): safe.c $(RUBY_H_INCLUDES) $(VM_CORE_H_INCLUDES) vm_opts.h internal.h
signal.$(OBJEXT): signal.c $(RUBY_H_INCLUDES) \
  $(VM_CORE_H_INCLUDES) vm_opts.h internal.h ruby_atomic.h eval_intern.h
sprintf.$(OBJEXT): sprintf.c $(RUBY_H_INCLUDES) re.h \
  regex.h vsnprintf.c $(ENCODING_H_INCLUDES) internal.h
st.$(OBJEXT): st.c $(RUBY_H_INCLUDES)
strftime.$(OBJEXT): strftime.c $(RUBY_H_INCLUDES) \
  timev.h $(ENCODING_H_INCLUDES)
string.$(OBJEXT): string.c $(RUBY_H_INCLUDES) re.h \
  regex.h $(ENCODING_H_INCLUDES) internal.h $(PROBES_H_INCLUDES) vm_opts.h node.h ruby_atomic.h vm_core.h vm_debug.h id.h method.h thread_$(THREAD_MODEL).h thread_native.h
struct.$(OBJEXT): struct.c $(RUBY_H_INCLUDES) internal.h
thread.$(OBJEXT): thread.c eval_intern.h \
  $(RUBY_H_INCLUDES) gc.h $(VM_CORE_H_INCLUDES) \
  thread_$(THREAD_MODEL).c $(ENCODING_H_INCLUDES) \
  internal.h io.h thread.h timev.h vm_opts.h
transcode.$(OBJEXT): transcode.c $(RUBY_H_INCLUDES) \
  $(ENCODING_H_INCLUDES) transcode_data.h internal.h
cont.$(OBJEXT): cont.c $(RUBY_H_INCLUDES) \
  $(VM_CORE_H_INCLUDES) gc.h eval_intern.h \
  internal.h vm_opts.h
time.$(OBJEXT): time.c $(RUBY_H_INCLUDES) \
  $(ENCODING_H_INCLUDES) timev.h internal.h
util.$(OBJEXT): util.c $(RUBY_H_INCLUDES) util.h \
  internal.h
variable.$(OBJEXT): variable.c $(RUBY_H_INCLUDES) \
  node.h util.h encoding.h id.h \
  oniguruma.h internal.h constant.h
version.$(OBJEXT): version.c $(RUBY_H_INCLUDES) \
  $(srcdir)/include/ruby/version.h $(srcdir)/version.h $(srcdir)/revision.h config.h
loadpath.$(OBJEXT): loadpath.c $(RUBY_H_INCLUDES) \
  $(srcdir)/include/ruby/version.h $(srcdir)/version.h config.h \
  verconf.h
localeinit.$(OBJEXT): localeinit.c $(RUBY_H_INCLUDES) \
  $(ENCODING_H_INCLUDES) internal.h
miniinit.$(OBJEXT): miniinit.c $(RUBY_H_INCLUDES) \
  $(ENCODING_H_INCLUDES)

compile.$(OBJEXT): compile.c iseq.h \
  $(RUBY_H_INCLUDES) $(VM_CORE_H_INCLUDES) insns.inc \
  insns_info.inc optinsn.inc \
  optunifs.inc opt_sc.inc insns.inc \
  internal.h vm_opts.h
iseq.$(OBJEXT): iseq.c gc.h iseq.h \
  $(RUBY_H_INCLUDES) $(VM_CORE_H_INCLUDES) insns.inc \
  insns_info.inc node_name.inc internal.h vm_opts.h ruby_atomic.h eval_intern.h
vm.$(OBJEXT): vm.c gc.h iseq.h \
  eval_intern.h $(RUBY_H_INCLUDES) $(ENCODING_H_INCLUDES) \
  $(VM_CORE_H_INCLUDES) vm_method.c vm_eval.c \
  vm_insnhelper.c vm_insnhelper.h vm_exec.c \
  vm_exec.h insns.def vmtc.inc \
  vm.inc insns.inc \
  internal.h vm.h constant.h \
  $(PROBES_H_INCLUDES) probes_helper.h vm_opts.h
vm_dump.$(OBJEXT): vm_dump.c $(RUBY_H_INCLUDES) \
  $(VM_CORE_H_INCLUDES) addr2line.h \
  internal.h vm_opts.h
debug.$(OBJEXT): debug.c $(RUBY_H_INCLUDES) \
  $(ENCODING_H_INCLUDES) $(VM_CORE_H_INCLUDES) eval_intern.h \
  util.h vm_opts.h internal.h
id.$(OBJEXT): id.c $(RUBY_H_INCLUDES) id.h vm_opts.h
vm_backtrace.$(OBJEXT): vm_backtrace.c \
  $(VM_CORE_H_INCLUDES) $(RUBY_H_INCLUDES) $(ENCODING_H_INCLUDES) \
  internal.h iseq.h debug.h vm_opts.h ruby_atomic.h eval_intern.h
vm_trace.$(OBJEXT): vm_trace.c $(ENCODING_H_INCLUDES) \
  $(VM_CORE_H_INCLUDES) $(RUBY_H_INCLUDES) debug.h \
  internal.h vm_opts.h ruby_atomic.h eval_intern.h
miniprelude.$(OBJEXT): miniprelude.c $(RUBY_H_INCLUDES) \
  $(VM_CORE_H_INCLUDES) internal.h vm_opts.h
prelude.$(OBJEXT): prelude.c $(RUBY_H_INCLUDES) \
  $(VM_CORE_H_INCLUDES) internal.h vm_opts.h
golf_prelude.$(OBJEXT): golf_prelude.c $(RUBY_H_INCLUDES) \
  $(VM_CORE_H_INCLUDES) internal.h vm_opts.h
goruby.$(OBJEXT): goruby.c main.c $(RUBY_H_INCLUDES) \
  vm_debug.h node.h $(hdrdir)/ruby.h

sizes.$(OBJEXT): sizes.c $(RUBY_H_INCLUDES)

ascii.$(OBJEXT): ascii.c regenc.h config.h \
  oniguruma.h missing.h $(RUBY_H_INCLUDES)
us_ascii.$(OBJEXT): us_ascii.c regenc.h \
  config.h oniguruma.h missing.h $(RUBY_H_INCLUDES)
unicode.$(OBJEXT): unicode.c regint.h \
  config.h defines.h regenc.h \
  oniguruma.h st.h ruby.h \
  missing.h intern.h \
  enc/unicode/name2ctype.h enc/unicode/casefold.h  \
  subst.h $(RUBY_H_INCLUDES)

utf_8.$(OBJEXT): utf_8.c regenc.h config.h \
  oniguruma.h missing.h $(RUBY_H_INCLUDES)

win32/win32.$(OBJEXT): win32/win32.c dln.h dln_find.c \
  internal.h $(RUBY_H_INCLUDES) $(PLATFORM_D)
win32/file.$(OBJEXT): win32/file.c $(RUBY_H_INCLUDES) $(PLATFORM_D)

$(NEWLINE_C): $(srcdir)/enc/trans/newline.trans $(srcdir)/tool/transcode-tblgen.rb
	$(Q) $(BASERUBY) "$(srcdir)/tool/transcode-tblgen.rb" -vo $@ $(srcdir)/enc/trans/newline.trans
newline.$(OBJEXT): $(NEWLINE_C) defines.h \
  intern.h missing.h st.h \
  transcode_data.h ruby.h config.h subst.h

verconf.h: $(srcdir)/template/verconf.h.in $(srcdir)/tool/generic_erb.rb $(RBCONFIG)
	$(ECHO) creating $@
	$(Q) $(MINIRUBY) "$(srcdir)/tool/generic_erb.rb" $(srcdir)/template/verconf.h.in > $@

DTRACE_DEPENDENT_OBJS = array.$(OBJEXT) \
		eval.$(OBJEXT) \
		gc.$(OBJEXT) \
		hash.$(OBJEXT) \
		load.$(OBJEXT) \
		object.$(OBJEXT) \
		parse.$(OBJEXT) \
		string.$(OBJEXT) \
		vm.$(OBJEXT)

probes.$(OBJEXT): $(DTRACE_DEPENDENT_OBJS)
ruby-glommed.$(OBJEXT): $(OBJS) $(DTRACE_OBJ)

$(OBJS):  config.h missing.h

INSNS2VMOPT = --srcdir="$(srcdir)"

minsns.inc: $(srcdir)/template/minsns.inc.tmpl

opt_sc.inc: $(srcdir)/template/opt_sc.inc.tmpl

optinsn.inc: $(srcdir)/template/optinsn.inc.tmpl

optunifs.inc: $(srcdir)/template/optunifs.inc.tmpl

insns.inc: $(srcdir)/template/insns.inc.tmpl

insns_info.inc: $(srcdir)/template/insns_info.inc.tmpl

vmtc.inc: $(srcdir)/template/vmtc.inc.tmpl

vm.inc: $(srcdir)/template/vm.inc.tmpl

srcs: parse.c lex.c newline.c id.c srcs-ext srcs-enc

EXT_SRCS = $(srcdir)/ext/ripper/ripper.c $(srcdir)/ext/json/parser/parser.c \
	   $(srcdir)/ext/dl/callback/callback.c  $(srcdir)/ext/rbconfig/sizeof/sizes.c

srcs-ext: $(EXT_SRCS)

srcs-enc: $(ENC_MK)
	$(ECHO) making srcs under enc
	$(Q) $(MAKE) -f $(ENC_MK) RUBY="$(MINIRUBY)" MINIRUBY="$(MINIRUBY)" $(MFLAGS) srcs

all-incs: incs
incs: $(INSNS) node_name.inc encdb.h transdb.h known_errors.inc \
      $(srcdir)/revision.h $(REVISION_H) enc/unicode/name2ctype.h id.h probes.dmyh

insns: $(INSNS)

id.h: $(srcdir)/tool/generic_erb.rb $(srcdir)/template/id.h.tmpl $(srcdir)/defs/id.def
	$(ECHO) generating $@
	$(Q) $(BASERUBY) $(srcdir)/tool/generic_erb.rb --output=$@ \
		$(srcdir)/template/id.h.tmpl

id.c: $(srcdir)/tool/generic_erb.rb $(srcdir)/template/id.c.tmpl $(srcdir)/defs/id.def
	$(ECHO) generating $@
	$(Q) $(BASERUBY) $(srcdir)/tool/generic_erb.rb --output=$@ \
		$(srcdir)/template/id.c.tmpl

node_name.inc: node.h
	$(ECHO) generating $@
	$(Q) $(BASERUBY) -n $(srcdir)/tool/node_name.rb < $? > $@

encdb.h: $(PREP) $(srcdir)/tool/generic_erb.rb $(srcdir)/template/encdb.h.tmpl
	$(ECHO) generating $@
	$(Q) $(MINIRUBY) $(srcdir)/tool/generic_erb.rb -c -o $@ $(srcdir)/template/encdb.h.tmpl $(srcdir)/enc enc

transdb.h: $(PREP) srcs-enc $(srcdir)/tool/generic_erb.rb $(srcdir)/template/transdb.h.tmpl
	$(ECHO) generating $@
	$(Q) $(MINIRUBY) $(srcdir)/tool/generic_erb.rb -c -o $@ $(srcdir)/template/transdb.h.tmpl $(srcdir)/enc/trans enc/trans

enc/encinit.c: $(ENC_MK) $(srcdir)/enc/encinit.c.erb

known_errors.inc: $(srcdir)/template/known_errors.inc.tmpl $(srcdir)/defs/known_errors.def
	$(ECHO) generating $@
	$(Q) $(BASERUBY) $(srcdir)/tool/generic_erb.rb -c -o $@ $(srcdir)/template/known_errors.inc.tmpl $(srcdir)/defs/known_errors.def

$(MINIPRELUDE_C): $(srcdir)/tool/compile_prelude.rb $(srcdir)/prelude.rb
	$(ECHO) generating $@
	$(Q) $(BASERUBY) -I$(srcdir) $(srcdir)/tool/compile_prelude.rb $(srcdir)/prelude.rb $@

prelude.c: $(srcdir)/tool/compile_prelude.rb $(RBCONFIG) \
	   $(srcdir)/lib/rubygems/defaults.rb \
	   $(srcdir)/lib/rubygems/core_ext/kernel_gem.rb \
	   $(PRELUDE_SCRIPTS) $(PREP)
	$(ECHO) generating $@
	$(Q) $(COMPILE_PRELUDE) $(PRELUDE_SCRIPTS) $@

golf_prelude.c: $(srcdir)/tool/compile_prelude.rb $(RBCONFIG) $(srcdir)/prelude.rb $(srcdir)/golf_prelude.rb $(PREP)
	$(ECHO) generating $@
	$(Q) $(COMPILE_PRELUDE) $(srcdir)/golf_prelude.rb $@

probes.dmyh: probes.d $(srcdir)/tool/gen_dummy_probes.rb
	$(BASERUBY) $(srcdir)/tool/gen_dummy_probes.rb $(srcdir)/probes.d > $@

probes.h: probes.$(DTRACE_EXT)

prereq: incs srcs preludes PHONY

preludes: miniprelude.c
preludes: golf_prelude.c

$(srcdir)/revision.h:
	@exit > $@

$(REVISION_H): $(srcdir)/version.h $(srcdir)/ChangeLog $(srcdir)/tool/file2lastrev.rb $(REVISION_FORCE)
	-$(Q) $(BASERUBY) $(srcdir)/tool/file2lastrev.rb --revision.h "$(srcdir)" > revision.tmp
	$(Q)$(IFCHANGE) "--timestamp=$@" "$(srcdir)/revision.h" revision.tmp

$(srcdir)/ext/ripper/ripper.c: parse.y id.h
	$(ECHO) generating $@
	$(Q) $(CHDIR) $(@D) && $(exec) $(MAKE) -f depend $(MFLAGS) \
		Q=$(Q) ECHO=$(ECHO) top_srcdir=../.. srcdir=. VPATH=../.. RUBY="$(BASERUBY)" PATH_SEPARATOR="$(PATH_SEPARATOR)"

$(srcdir)/ext/json/parser/parser.c: $(srcdir)/ext/json/parser/parser.rl
	$(ECHO) generating $@
	$(Q) $(CHDIR) $(@D) && $(exec) $(MAKE) -f prereq.mk $(MFLAGS) \
		Q=$(Q) ECHO=$(ECHO) top_srcdir=../../.. srcdir=. VPATH=../../.. BASERUBY="$(BASERUBY)"

$(srcdir)/ext/dl/callback/callback.c: $(srcdir)/ext/dl/callback/mkcallback.rb $(srcdir)/ext/dl/dl.h
	$(ECHO) generating $@
	$(Q) $(CHDIR) $(@D) && $(exec) $(MAKE) -f depend $(MFLAGS) \
		Q=$(Q) ECHO=$(ECHO) top_srcdir=../.. srcdir=. VPATH=../.. RUBY="$(BASERUBY)"

$(srcdir)/ext/rbconfig/sizeof/sizes.c: $(srcdir)/ext/rbconfig/sizeof/depend \
		$(srcdir)/tool/generic_erb.rb $(srcdir)/template/sizes.c.tmpl $(srcdir)/configure.in
	$(ECHO) generating $@
	$(Q) $(CHDIR) $(@D) && $(exec) $(MAKE) -f depend $(MFLAGS) \
		Q=$(Q) ECHO=$(ECHO) top_srcdir=../../.. srcdir=. VPATH=../../.. RUBY="$(BASERUBY)"

##

run: fake miniruby$(EXEEXT) PHONY
	$(BTESTRUBY) $(TESTRUN_SCRIPT) $(RUNOPT)

runruby: $(PROGRAM) PHONY
	$(RUNRUBY) $(TESTRUN_SCRIPT)

parse: fake miniruby$(EXEEXT) PHONY
	$(BTESTRUBY) $(srcdir)/tool/parse.rb $(TESTRUN_SCRIPT)

bisect: PHONY
	$(srcdir)/tool/bisect.sh miniruby $(srcdir)

bisect-ruby: PHONY
	$(srcdir)/tool/bisect.sh ruby $(srcdir)

COMPARE_RUBY = $(BASERUBY)
ITEM =
OPTS =

benchmark: $(PROGRAM) PHONY
	$(BASERUBY) $(srcdir)/benchmark/driver.rb -v \
	            --executables="$(COMPARE_RUBY); built-ruby::$(RUNRUBY)" \
	            --pattern='bm_' --directory=$(srcdir)/benchmark $(OPTS)

benchmark-each: $(PROGRAM) PHONY
	$(BASERUBY) $(srcdir)/benchmark/driver.rb -v \
	            --executables="$(COMPARE_RUBY); built-ruby::$(RUNRUBY)" \
	            --pattern=$(ITEM) --directory=$(srcdir)/benchmark $(OPTS)

tbench: $(PROGRAM) PHONY
	$(BASERUBY) $(srcdir)/benchmark/driver.rb -v \
	            --executables="$(COMPARE_RUBY); built-ruby::$(RUNRUBY)" \
	            --pattern='bmx_' --directory=$(srcdir)/benchmark $(OPTS)

run.gdb:
	echo set breakpoint pending on         > run.gdb
	echo b ruby_debug_breakpoint          >> run.gdb
	echo '# handle SIGINT nostop'         >> run.gdb
	echo '# handle SIGPIPE nostop'        >> run.gdb
	echo '# b rb_longjmp'                 >> run.gdb
	echo source $(srcdir)/breakpoints.gdb >> run.gdb
	echo source $(srcdir)/.gdbinit        >> run.gdb
	echo 'set $$_exitcode = -999'         >> run.gdb
	echo run                              >> run.gdb
	echo 'if $$_exitcode != -999'         >> run.gdb
	echo '  quit'                         >> run.gdb
	echo end                              >> run.gdb


gdb: miniruby$(EXEEXT) run.gdb PHONY
	gdb -x run.gdb --quiet --args $(MINIRUBY) $(TESTRUN_SCRIPT)

gdb-ruby: $(PROGRAM) run.gdb PHONY
	$(Q) $(RUNRUBY_COMMAND) $(RUNRUBY_DEBUGGER) -- $(TESTRUN_SCRIPT)

dist:
	$(BASERUBY) $(srcdir)/tool/make-snapshot tmp $(RELNAME)

up::
	-$(Q)$(MAKE) $(MFLAGS) REVISION_FORCE=PHONY "$(REVISION_H)"

update-config_files: $(srcdir)/tool/config.guess $(srcdir)/tool/config.sub
$(srcdir)/tool/config.guess:
	$(Q) $(BASERUBY) -C $(@D) get-config_files $(@F)
$(srcdir)/tool/config.sub:
	$(Q) $(BASERUBY) -C $(@D) get-config_files $(@F)

info: info-program info-libruby_a info-libruby_so info-arch
info-program:
	@echo PROGRAM=$(PROGRAM)
info-libruby_a:
	@echo LIBRUBY_A=$(LIBRUBY_A)
info-libruby_so:
	@echo LIBRUBY_SO=$(LIBRUBY_SO)
info-arch:
	@echo arch=$(arch)

change: PHONY
	$(BASERUBY) -C "$(srcdir)" ./tool/change_maker.rb $(CHANGES) > change.log

love: sudo-precheck up all test install test-all
	@echo love is all you need

yes-test-all: sudo-precheck

sudo-precheck:
	@$(SUDO) echo > $(NULL)

help: PHONY
	$(MESSAGE_BEGIN) \
	"                Makefile of Ruby" \
	"" \
	"targets:" \
	"  all (default):   builds all of below" \
	"  miniruby:        builds only miniruby" \
	"  encs:            builds encodings" \
	"  exts:            builds extensions" \
	"  main:            builds encodings, extensions and ruby" \
	"  docs:            builds documents" \
	"  run:             runs test.rb by miniruby" \
	"  runruby:         runs test.rb by ruby you just built" \
	"  gdb:             runs test.rb by miniruby under gdb" \
	"  gdb-ruby:        runs test.rb by ruby under gdb" \
	"  check:           equals make test test-all" \
	"  test:            ruby core tests" \
	"  test-all:        all ruby tests [TESTS=<test files>]" \
	"  test-rubyspec:   run RubySpec test suite" \
	"  update-rubyspec: update local copy of RubySpec" \
	"  benchmark:       benchmark this ruby and COMPARE_RUBY" \
	"  gcbench:         gc benchmark [GCBENCH_ITEM=<item_name>]" \
	"  gcbench-rdoc:    gc benchmark with GCBENCH_ITEM=rdoc" \
	"  install:         install all ruby distributions" \
	"  install-nodoc:   install without rdoc" \
	"  install-cross:   install cross compiling staff" \
	"  clean:           clean for tarball" \
	"  distclean:       clean for repository" \
	"  change:          make change log template" \
	"  golf:            for golfers" \
	"" \
	"see DeveloperHowto for more detail: " \
	"  http://bugs.ruby-lang.org/wiki/ruby/DeveloperHowto" \
	$(MESSAGE_END)
