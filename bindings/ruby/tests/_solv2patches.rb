#
# Convert .solv file to Code11 Patches
#

require 'satsolver'
require '_patch'

def store_it the_store, name, s
  byname = the_store[name] || Hash.new
  STDERR.puts "* known #{name}-#{s.evr}" if byname[s.evr]
  byname[s.evr] = s
  the_store[name] = byname
  the_store
end

def solv2patches name, arch

  pool = SatSolver::Pool.new( arch )
  repo = pool.create_repo( "patches" )
  repo.add_solv( name )
  STDERR.puts "#{repo.size} patches and stuff"

  atoms = Hash.new
  patches = Hash.new


  #
  # Iterate through repo
  # - ensure that it contains only patches and atoms
  # - store all patches in 'patches'
  # - store all atoms in 'atoms'
  # - both stores are 2-dim hashed, first dim is name, second dim is evr
  #

  repo.each { |s|
    sp = s.name.split ":"
    unless sp.size == 2
      STDERR.puts "** No kind #{s}"
      exit
    end
    kind = sp[0]
    case kind
    when "atom"
      atoms = store_it atoms, sp[1], s
    when "patch"
      patches = store_it patches, sp[1], s
    else
      STDERR.puts "** Unknown kind #{kind} of #{s}"
    end
  }

  #
  # Now iterate through all patches
  # - ensure that it requires just atoms
  # - by equality
  # - find the atom
  # - ensure that the atom has proper deps
  #

  out_patches = []
  
  patches.each { |name,store|
    store.each { |evr,patch|

      p = Patch.new( name, evr, patch.category, patch.timestamp )
      p.summary = patch.summary
      p.description = patch.description
      
      patch.requires.each { |req|
	sp = req.name.split ":"
	
	unless sp.size == 2
	  STDERR.puts "** Patch #{patch} requires #{req}"
	  exit
	end
	unless sp[0] == "atom"
	  STDERR.puts "** Patch #{patch} requires non-atom #{sp[0]}"
	  exit
	end
	name = sp[1]
	byname = atoms[name]
	unless byname
	  STDERR.puts "** Patch #{patch} requires unknown atom #{name}"
	  exit
	end
	unless req.op == SatSolver::REL_EQ
	  STDERR.puts "** Patch #{patch} requires non-equal atom #{name}"
	  exit
	end
	atom = byname[req.evr]
	unless atom
	  STDERR.puts "** Patch #{patch} requires non-existing atom #{req.name}-#{req.evr}"
	  exit
	end
	atom.freshens.each { |fre|
	  unless fre.name == name
	    STDERR.puts "Atom #{atom} freshens #{fre}"
	    exit
	  end
	}
	atom.requires.each { |areq|
	  sp = areq.name.split ":"
	  unless sp.size == 1
	    STDERR.puts "Atom #{atom} requires #{areq}"
	    exit
	  end
	  unless areq.op == SatSolver::REL_GE
	    STDERR.puts "Atom #{atom} requires non-greater-equal #{areq}"
	    exit
	  end
	  p.add( areq.name, areq.evr, atom.arch )
	}
      }
      out_patches << p
    }
  }
  
  out_patches
end