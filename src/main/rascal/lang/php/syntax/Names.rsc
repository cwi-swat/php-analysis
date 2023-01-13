module lang::php::\syntax::Names

import String;

public data NameQualification // qualified -> not fullyQualified
	= unqualified()
	| qualified()
	| fullyQualified();


public NameQualification getNameQualification(str phpName)
{
	str name = replaceAll(phpName, "\\", "/");

	if (/^\/.*$/ := name)
	{
		return fullyQualified();
	}
	else if (/^.+\/.*$/ := name)
	{
		return qualified();
	}
	else
	{
		return unqualified();
	}	
}


public str getLastNamePart(str phpName)
{
	str name = replaceAll(phpName, "\\", "/");

	if (/^.*\/<lastName:[^\/]*>$/ := "/" + name)
	{
		return lastName;
	}
	return phpName; // TODO ??
}
