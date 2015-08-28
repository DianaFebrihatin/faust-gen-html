<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:f="http://www.faustedition.net/ns"
  xmlns:pxf="http://exproc.org/proposed/steps/file"  
  xmlns:l="http://xproc.org/library" type="f:list-transcripts" name="main" version="1.0">

  <p:input port="source"><p:empty/></p:input>
  <p:input port="parameters" kind="parameter"/>
  
  

  <p:import href="http://xproc.org/library/recursive-directory-list.xpl"/>
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

  <!-- Parameter laden -->
  <p:parameters name="config">
    <p:input port="parameters">
      <p:document href="config.xml"/>
      <p:pipe port="parameters" step="main"></p:pipe>
    </p:input>
  </p:parameters>

  <p:group>
    <p:variable name="metahtml" select="//c:param[@name='metahtml']/@value"><p:pipe port="result" step="config"></p:pipe></p:variable>
    <p:variable name="source" select="//c:param[@name='source']/@value"><p:pipe port="result" step="config"/></p:variable>
    <p:variable name="debug" select="//c:param[@name='debug']/@value"><p:pipe port="result" step="config"/></p:variable>
    <cx:message log="info">  
      <p:input port="source"><p:pipe port="source" step="main"></p:pipe></p:input>      
      <p:with-option name="message" select="concat('Collecting metadata from ', $source)"/>
    </cx:message>
        


    <l:recursive-directory-list>
      <p:with-option name="path" select="concat($source, '/document')"/>
    </l:recursive-directory-list>

    <p:for-each>
      <p:iteration-source select="//c:file[$debug or not(ends-with(@name, 'test.xml'))]"/>
      <p:variable name="filename" select="p:resolve-uri(/c:file/@name)"/>
      <p:variable name="basename" select="replace(replace($filename, '.*/', ''), '.xml$', '')"/>
      <p:variable name="outfile" select="concat($metahtml, $basename, '.html')"/>
      
      <cx:message log="info">        
        <p:with-option name="message" select="concat('Converting ', $filename, ' to ', $outfile)"/>
      </cx:message>
      
      <p:load>
        <p:with-option name="href" select="$filename"/>
      </p:load>

      <p:xslt>
        <p:input port="stylesheet"><p:document href="faust-metadata.xsl"/></p:input>
        <p:input port="parameters"><p:pipe port="result" step="config"/></p:input>
      </p:xslt>
      
      <p:store encoding="utf-8" method="xhtml" include-content-type="false" indent="true">
        <p:with-option name="href" select="$outfile"/>
      </p:store>
      
    </p:for-each>    
  </p:group>

</p:declare-step>
