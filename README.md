#DZ_DICT
Utilities for the manipulation of the Oracle data dictionary.
For the most up-to-date documentation see the auto-build  [dz_dict_deploy.pdf](https://github.com/pauldzy/DZ_DICT/blob/master/dz_dict_deploy.pdf).

##Installation
Simply execute the deployment script into the schema of your choice.  Then execute the code using either the same or a different schema.  All procedures and functions are publically executable and utilize AUTHID CURRENT_USER for permissions handling.

##Collaboration
Forks and pulls are **most** welcome.  The deployment script and deployment documentation files in the repository root are generated by my [build system](https://github.com/pauldzy/Speculative_PLSQL_CI) which obviously you do not have.  You can just ignore those files and when I merge your pull my system will autogenerate updated files for GitHub.

##Oracle Licensing Disclaimer
Oracle places the burden of matching functionality usage with server licensing entirely upon the user.  In the realm of Oracle Spatial, some features are "[spatial](http://download.oracle.com/otndocs/products/spatial/pdf/12c/oraspatitalandgraph_12_fo.pdf)" (and thus a separate purchased "option" beyond enterprise) and some are "[locator](http://download.oracle.com/otndocs/products/spatial/pdf/12c/oraspatialfeatures_12c_fo_locator.pdf)" (bundled with standard and enterprise).  This differentiation is ever changing.  Thus the definition for 11g is not exactly the same as the definition for 12c.  If you are seeking to utilize my code **without** a full Spatial option license, I do provide a good faith estimate of the licensing required and when coding I am conscious of keeping repository functionality to the simplest licensing level when possible.  However - as all such things go - the final burden of determining if functionality in a given repository matches your server licensing is entirely placed upon the user.  You should **always** fully inspect the code and its usage of Oracle functionality in light of your licensing.  Any reliance you place on my estimation is therefore strictly at your own risk.

In my estimation functionality in the DZ_SPIDX repository should match Oracle Locator licensing for 10g, 11g and 12c.
