sub activateOracle {

	my $env_oracle_home = "/usr/oracle_instantClient64";	 # For $ENV_ORACLE_HOME
	my $host = "192.168.67.9";
	my $port = "1521";
	my $sid = "CFE9ir2";
	my $user="l_scripts";
	my $password="labdog99";

	return ($env_oracle_home, $host, $port, $sid, $user, $password);
	}

1;
