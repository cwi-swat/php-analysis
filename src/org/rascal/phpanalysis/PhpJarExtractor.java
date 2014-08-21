package org.rascal.phpanalysis;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.util.Enumeration;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.rascalmpl.interpreter.utils.RuntimeExceptionFactory;

public class PhpJarExtractor {
	protected final IValueFactory values;
	
	public PhpJarExtractor(IValueFactory values){
		this.values = values;
	}
		
	public IValue getPhpParserLocFromJar() throws IOException {
		InputStream is = null;
		FileOutputStream fo = null;
		JarFile jarFile = null;
		
		try {
			File tempDir = Files.createTempDirectory("rascal-php-parser-jar").toAbsolutePath().toFile();
			File tempJar = new File(tempDir, "php-parser.jar");
			
			//System.out.println(getClass().getClassLoader().);
			
			if (!tempJar.exists()) {
				Files.copy(getClass().getClassLoader().getResourceAsStream("php-parser.jar"), tempJar.toPath());
			}		
			
			jarFile = new JarFile(tempJar);
			Enumeration<JarEntry> entries = jarFile.entries();
			
		    while (entries.hasMoreElements())
		    {
		        JarEntry je = entries.nextElement();
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
		        
		        is = jarFile.getInputStream(je);
		        fo = new FileOutputStream(fl);
		        
		        while (is.available() > 0)
		        {
		            fo.write(is.read());
		        }
		        
		        fo.close();
		        is.close();
		        
		        fo = null;
		        is = null;
		    }
	
		    return values.sourceLocation(tempDir.getAbsolutePath());
		}
		catch(IOException ioex) {
			throw RuntimeExceptionFactory.io(values.string(ioex.getMessage()), null, null);
		}
		finally {
			if (fo != null)	fo.close();
	        if (is != null) is.close();
	        if (jarFile != null) jarFile.close();
		}
	}
}
