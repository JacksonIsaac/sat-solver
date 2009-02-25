$:.unshift "../../../build/bindings/ruby"
require 'pathname'

# test Transction

require 'test/unit'
require 'satsolver'

class TransactionTest < Test::Unit::TestCase
  def test_transaction
    pool = Satsolver::Pool.new
    assert pool
    pool.arch = "i686"
    solvpath = Pathname( File.dirname( __FILE__ ) ) + Pathname( "../../testdata" ) + "os11-biarch.solv"
    repo = pool.add_solv( solvpath )
    repo.name = "test1"
    
    transaction = Satsolver::Transaction.new( pool )
    assert transaction
    transaction.install( "foo" )
    transaction.install( repo.find "ruby" )
    transaction.install( Satsolver::Relation.new( pool, "foo", Satsolver::REL_EQ, "42-7" ) )
    transaction.remove( "bar" )
    transaction.remove( repo.find "glibc" )
    transaction.remove( Satsolver::Relation.new( pool, "bar", Satsolver::REL_EQ, "42-7" ) )
    assert transaction.size == 6
    transaction.each { |a|
      cmd = case a.cmd
            when Satsolver::INSTALL_SOLVABLE: "install #{a.solvable}"
	    when Satsolver::REMOVE_SOLVABLE: "remove #{a.solvable}"
	    when Satsolver::INSTALL_SOLVABLE_NAME: "install by name #{a.name}"
	    when Satsolver::REMOVE_SOLVABLE_NAME: "remove by name #{a.name}"
	    when Satsolver::INSTALL_SOLVABLE_PROVIDES: "install by relation #{a.relation}"
	    when Satsolver::REMOVE_SOLVABLE_PROVIDES: "remove by relation #{a.relation}"
	    else "<NONE>"
	    end
      puts cmd
    }
    transaction.clear!
    assert transaction.empty?
  end
end
