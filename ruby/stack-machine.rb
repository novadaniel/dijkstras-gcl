module GCL
  def emptyState
    lambda { |_| 0 }
  end

  def updateState(sigma, x, n)
    lambda { |i| i == x ? n : sigma.call(i) }
  end

  def stackEval(control, results, memory)
    while control.any?
      current = control.pop
      case current
      in Symbol
        case current
        when :plus
          n1 = results.pop
          n2 = results.pop
          results.push(n1+n2)
        when :minus
          n1 = results.pop
          n2 = results.pop
          results.push(n1-n2)
        when :times
          n1 = results.pop
          n2 = results.pop
          results.push(n1*n2)
        when :div
          n1 = results.pop
          n2 = results.pop
          results.push(n1/n2)
        when :eq
          n1 = results.pop
          n2 = results.pop
          results.push(n1 == n2)
        when :less
          n1 = results.pop
          n2 = results.pop
          results.push(n1 < n2)
        when :greater
          n1 = results.pop
          n2 = results.pop
          results.push(n1 > n2)
        when :and
          n1 = results.pop
          n2 = results.pop
          n = (n1 and n2)
          results.push(n)
        when :or
          n1 = results.pop
          n2 = results.pop
          n = (n1 or n2)
          results.push(n)
        when :assign
          n = results.pop
          var = control.pop
          memory = updateState(memory, var, n)
        when :if
          n = results.pop
          if n
            s = control.pop
            control.pop
            control.push(s)
          else
            control.pop
          end
        when :do
          n = results.pop
          if n
            b = control.pop
            s = control.pop
            control.push(GCDo.new([[b, s]]))
            control.push(s)
          else
            control.pop
            control.pop
          end
        else
          throw "Not a valid symbol"
        end
      in GCConst
        results.push(current.val)
      in GCVar
        results.push(memory.call(current.name))
      in GCOp
        control.push(current.sym)
        control.push(current.expr1)
        control.push(current.expr2)
      in GCTrue
        results.push(true)
      in GCFalse
        results.push(false)
      in GCComp
        control.push(current.sym)
        control.push(current.expr1)
        control.push(current.expr2)
      in GCAnd
        control.push(:and)
        control.push(current.test1)
        control.push(current.test2)
      in GCOr
        control.push(:or)
        control.push(current.test1)
        control.push(current.test2)
      in GCSkip
      in GCAssign
        control.push(current.sym)
        control.push(:assign)
        control.push(current.expr)
      in GCCompose
        control.push(current.stmt2)
        control.push(current.stmt1)
      in GCIf
        head, *tail = current.pairs.shuffle
        if tail.empty?
          control.push(GCSkip.new)
        else
          control.push(GCIf.new(tail))
        end
        control.push(head[1])
        control.push(:if)
        control.push(head[0])
      in GCDo
        current.pairs.shuffle.each { |pair|
          control.push(pair[1])
          control.push(pair[0])
          control.push(:do)
          control.push(pair[0])
        }
      else
        throw "Class does not exist"
      end
    end
    memory
  end

  class GCExpr; end

  class GCConst < GCExpr
    attr_reader :val

    def initialize(val)
      unless val.is_a?(Integer)
        throw "TypeError: GCConst expected (Integer), instead got (" + val.class.to_s + ")"
      end
      @val = val
    end
  end

  class GCVar < GCExpr
    attr_reader :name

    def initialize(name)
      unless name.is_a?(Symbol)
        throw "TypeError: GCVar expected (Symbol), instead got (" + name.class.to_s + ")"
      end
      @name = name
    end
  end

  class GCOp < GCExpr
    attr_reader :expr1
    attr_reader :expr2
    attr_reader :sym

    def initialize(expr1, expr2, sym)
      unless expr1.is_a?(GCExpr) and expr2.is_a?(GCExpr) and sym.is_a?(Symbol)
        throw "TypeError: GCOp expected (GCExpr, GCExpr, Symbol), instead got (" + expr1.class.to_s + ", " + expr2.class.to_s + ", " + sym.class.to_s + ")"
      end
      @expr1 = expr1
      @expr2 = expr2
      @sym = sym
    end
  end


  class GCTest; end

  class GCComp < GCTest
    attr_reader :expr1
    attr_reader :expr2
    attr_reader :sym

    def initialize(expr1, expr2, sym)
      unless expr1.is_a?(GCExpr) and expr2.is_a?(GCExpr) and sym.is_a?(Symbol)
        throw "TypeError: GCComp expected (GCExpr, GCExpr, Symbol), instead got (" + expr1.class.to_s + ", " + expr2.class.to_s + ", " + sym.class.to_s + ")"
      end
      @expr1 = expr1
      @expr2 = expr2
      @sym = sym
    end
  end

  class GCAnd < GCTest
    attr_reader :test1
    attr_reader :test2

    def initialize(test1, test2)
      unless test1.is_a?(GCTest) and test2.is_a?(GCTest)
        throw "TypeError: GCAnd expected (GCTest, GCTest), instead got (" + test1.class.to_s + ", " + test2.class.to_s + ")"
      end
      @test1 = test1
      @test2 = test2
    end
  end

  class GCOr < GCTest
    attr_reader :test1
    attr_reader :test2

    def initialize(test1, test2)
      unless test1.is_a?(GCTest) and test2.is_a?(GCTest)
        throw "TypeError: GCOr expected (GCTest, GCTest), instead got (" + test1.class.to_s + ", " + test2.class.to_s + ")"
      end
      @test1 = test1
      @test2 = test2
    end
  end

  class GCTrue < GCTest
  end

  class GCFalse < GCTest
  end

  class GCStmt; end

  class GCSkip < GCStmt
  end

  class GCAssign < GCStmt
    attr_reader :sym
    attr_reader :expr

    def initialize(sym, expr)
      unless sym.is_a?(Symbol) and expr.is_a?(GCExpr)
        throw "TypeError: GCAssign expected (Symbol, GCExpr), instead got (" + sym.class.to_s + ", " + expr.class.to_s + ")"
      end
      @sym = sym
      @expr = expr
    end
  end

  class GCCompose < GCStmt
    attr_reader :stmt1
    attr_reader :stmt2

    def initialize(stmt1, stmt2)
      unless stmt1.is_a?(GCStmt) and stmt2.is_a?(GCStmt)
        throw "TypeError: GCCompose expected (GCStmt, GCStmt), instead got (" + stmt1.class.to_s + ", " + stmt2.class.to_s + ")"
      end
      @stmt1 = stmt1
      @stmt2 = stmt2
    end
  end

  class GCIf < GCStmt
    attr_reader :pairs

    def initialize(pairs)
      unless pairs.is_a?(Array)
        throw "TypeError: GCIf expected (Array), instead got (" + pairs.class.to_s + ")"
      end
      @pairs = pairs
    end
  end

  class GCDo < GCStmt
    attr_reader :pairs

    def initialize(pairs)
      unless pairs.is_a?(Array)
        throw "TypeError: GCDo expected (Array), instead got (" + pairs.class.to_s + ")"
      end
      @pairs = pairs
    end
  end
end




module GCLe
  def eval(prog)
    unless prog.is_a?(GCProgram)
      throw "TypeError: wellScoped expected (GCProgram), instead got (" + prog.class.to_s + ")"
    end
    memory = {}
    prog.names.each { |sym|
      memory[sym] = nil
    }
    prog.stmt.evaluate(memory)
  end

  def wellScoped(prog)
    unless prog.is_a?(GCProgram)
      throw "TypeError: wellScoped expected (GCProgram), instead got (" + prog.class.to_s + ")"
    end

    scope = prog.names
    prog.stmt.checkScope(scope)
  end

  class GCExpr; end

  class GCConst < GCExpr
    attr_reader :val

    def initialize(val)
      unless val.is_a?(Integer)
        throw "TypeError: GCConst expected an Integer, instead got " + val.class.to_s
      end
      @val = val
    end

    def checkScope(_)
      true
    end

    def evaluate(_)
      @val
    end
  end

  class GCVar < GCExpr
    attr_reader :name

    def initialize(name)
      unless name.is_a?(Symbol)
        throw "TypeError: GCVar expected a Symbol, instead got " + name.class.to_s
      end
      @name = name
    end

    def checkScope(scope)
      scope.include?(@name)
    end

    def evaluate(memory)
      memory[@name]
    end
  end

  class GCOp < GCExpr
    attr_reader :expr1
    attr_reader :expr2
    attr_reader :sym

    def initialize(expr1, expr2, sym)
      unless expr1.is_a?(GCExpr) and expr2.is_a?(GCExpr) and sym.is_a?(Symbol)
        throw "TypeError: GCOp expected (GCExpr, GCExpr, Symbol), instead got (" + expr1.class.to_s + ", " + expr2.class.to_s + ", " + sym.class.to_s + ")"
      end
      @expr1 = expr1
      @expr2 = expr2
      @sym = sym
    end

    def checkScope(scope)
      @expr1.checkScope(scope) and @expr2.checkScope(scope)
    end

    def evaluate(memory)
      case @sym
      when :plus
        @expr1.evaluate(memory) + @expr2.evaluate(memory)
      when :minus
        @expr1.evaluate(memory) - @expr2.evaluate(memory)
      when :times
        @expr1.evaluate(memory) * @expr2.evaluate(memory)
      when :div
        @expr1.evaluate(memory) / @expr2.evaluate(memory)
      else
        throw "Not a valid Symbol"
      end
    end
  end


  class GCTest; end

  class GCComp < GCTest
    attr_reader :expr1
    attr_reader :expr2
    attr_reader :sym

    def initialize(expr1, expr2, sym)
      unless expr1.is_a?(GCExpr) and expr2.is_a?(GCExpr) and sym.is_a?(Symbol)
        throw "TypeError: GCComp expected (GCExpr, GCExpr, Symbol), instead got (" + expr1.class.to_s + ", " + expr2.class.to_s + ", " + sym.class.to_s + ")"
      end
      @expr1 = expr1
      @expr2 = expr2
      @sym = sym
    end

    def checkScope(scope)
      @expr1.checkScope(scope) and @expr2.checkScope(scope)
    end

    def evaluate(memory)
      case @sym
      when :eq
        @expr1.evaluate(memory) == @expr2.evaluate(memory)
      when :less
        @expr1.evaluate(memory) < @expr2.evaluate(memory)
      when :greater
        @expr1.evaluate(memory) > @expr2.evaluate(memory)
      end
    end
  end

  class GCAnd < GCTest
    attr_reader :test1
    attr_reader :test2

    def initialize(test1, test2)
      unless test1.is_a?(GCTest) and test2.is_a?(GCTest)
        throw "TypeError: GCAnd expected (GCTest, GCTest), instead got (" + test1.class.to_s + ", " + test2.class.to_s + ")"
      end
      @test1 = test1
      @test2 = test2
    end

    def checkScope(scope)
      @test1.checkScope(scope) and @test2.checkScope(scope)
    end

    def evaluate(memory)
      @test1.evaluate(memory) and @test2.evaluate(memory)
    end
  end

  class GCOr < GCTest
    attr_reader :test1
    attr_reader :test2

    def initialize(test1, test2)
      unless test1.is_a?(GCTest) and test2.is_a?(GCTest)
        throw "TypeError: GCOr expected (GCTest, GCTest), instead got (" + test1.class.to_s + ", " + test2.class.to_s + ")"
      end
      @test1 = test1
      @test2 = test2
    end

    def checkScope(scope)
      @test1.checkScope(scope) and @test2.checkScope(scope)
    end

    def evaluate(memory)
      @test1.evaluate(memory) or @test2.evaluate(memory)
    end
  end

  class GCTrue < GCTest
    def checkScope(_)
      true
    end
    def evaluate(_)
      true
    end
  end

  class GCFalse < GCTest
    def checkScope(_)
      true
    end
    def evaluate(_)
      false
    end
  end

  class GCStmt; end

  class GCSkip < GCStmt
    def checkScope(_)
      true
    end

    def evaluate(memory)
       memory
    end
  end

  class GCAssign < GCStmt
    attr_reader :sym
    attr_reader :expr

    def initialize(sym, expr)
      unless sym.is_a?(Symbol) and expr.is_a?(GCExpr)
        throw "TypeError: GCAssign expected (Symbol, GCExpr), instead got (" + sym.class.to_s + ", " + expr.class.to_s + ")"
      end
      @sym = sym
      @expr = expr
    end

    def checkScope(scope)
      scope.include?(@sym) and @expr.checkScope(scope)
    end

    def evaluate(memory)
      memory[@sym] = @expr.evaluate(memory)
      memory
    end
  end

  class GCCompose < GCStmt
    attr_reader :stmt1
    attr_reader :stmt2

    def initialize(stmt1, stmt2)
      unless stmt1.is_a?(GCStmt) and stmt2.is_a?(GCStmt)
        throw "TypeError: GCCompose expected (GCStmt, GCStmt), instead got (" + stmt1.class.to_s + ", " + stmt2.class.to_s + ")"
      end
      @stmt1 = stmt1
      @stmt2 = stmt2
    end

    def checkScope(scope)
      @stmt1.checkScope(scope) and @stmt2.checkScope(scope)
    end

    def evaluate(memory)
      memory = @stmt1.evaluate(memory)
      @stmt2.evaluate(memory)
    end
  end

  class GCIf < GCStmt
    attr_reader :pairs

    def initialize(pairs)
      unless pairs.is_a?(Array)
        throw "TypeError: GCIf expected (Array), instead got (" + pairs.class.to_s + ")"
      end
      @pairs = pairs
    end

    def checkScope(scope)
      @pairs.each { |pair|
        pair[0].checkScope(scope) and pair[1].checkScope(scope)
      }
    end

    def evaluate(memory)
      @pairs.shuffle.each { |pair|
        if pair[0].evaluate(memory)
          return pair[1].evaluate(memory)
        end
      }
      memory
    end
  end

  class GCDo < GCStmt
    attr_reader :pairs

    def initialize(pairs)
      unless pairs.is_a?(Array)
        throw "TypeError: GCDo expected (Array), instead got (" + pairs.class.to_s + ")"
      end
      @pairs = pairs
    end

    def checkScope(scope)
      @pairs.each { |pair|
        pair[0].checkScope(scope) and pair[1].checkScope(scope)
      }
    end

    def evaluate(memory)
      @pairs.shuffle.each { |pair|
        while pair[0].evaluate(memory)
          memory = pair[1].evaluate(memory)
        end
      }
      memory
    end
  end

  class GCLocal < GCStmt
    attr_reader :name
    attr_reader :stmt

    def initialize(name, stmt)
      unless name.is_a?(Symbol) and stmt.is_a?(GCStmt)
        throw "TypeError: GCLocal expected (Symbol, GCStmt), instead got (" + name.class.to_s + ", " + stmt.class.to_s + ")"
      end
      @name = name
      @stmt = stmt
    end

    def checkScope(scope)
      @stmt.checkScope(scope.push(@name))
    end

    def evaluate(memory)
      memory[@name] = nil
      @stmt.evaluate(memory)
    end
  end

  class GCProgram
    attr_reader :names
    attr_reader :stmt

    def initialize(names, stmt)
      unless names.is_a?(Array) and stmt.is_a?(GCStmt)
        throw "TypeError: GCProgram expected (Array, GCStmt), instead got (" + names.class.to_s + ", " + stmt.class.to_s + ")"
      end
      @names = names
      @stmt = stmt
    end
  end
end