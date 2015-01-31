package org.rascal.phpanalysis;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.jar.JarEntry;
import java.util.jar.JarInputStream;

import org.eclipse.imp.pdb.facts.ISourceLocation;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.IValueFactory;

public class PhpJarExtractor {
	protected final IValueFactory values;
	private static ISourceLocation phpParserLoc = null;
	
	public PhpJarExtractor(IValueFactory values){
		this.values = values;
	}
		
	public IValue getPhpParserLocFromJar() throws IOException {
		if (phpParserLoc == null) {
			File tempDir = Files.createTempDirectory("rascal-php-parser-jar").toAbsolutePath().toFile();
	
			try (JarInputStream jarStream = new JarInputStream(getClass().getClassLoader().getResourceAsStream("php-parser.jar"))) {	
				JarEntry je;
			    while ((je = jarStream.getNextJarEntry()) != null)
			    {
			        File fl = new File(tempDir, je.getName());
			        
			        if (!fl.exists())
			        {
			            fl.getParentFile().mkdirs();
			            //fl = new File(tempDir, je.getName());
			        }
			        if (je.isDirectory())
			        {
			            continue;
			        }
			        
			        Files.copy(jarStream, fl.toPath(), StandardCopyOption.REPLACE_EXISTING);
			    }
		
			    phpParserLoc = values.sourceLocation(tempDir.getAbsolutePath() + "/PHP-Parser/");
			}
		}
		return phpParserLoc;
	}
}
