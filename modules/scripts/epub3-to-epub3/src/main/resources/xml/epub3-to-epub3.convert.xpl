<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:d="http://www.daisy.org/ns/pipeline/data"
                xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
                xmlns:ocf="urn:oasis:names:tc:opendocument:xmlns:container"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:opf="http://www.idpf.org/2007/opf"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:rendition="http://www.idpf.org/2013/rendition"
                exclude-inline-prefixes="#all"
                type="px:epub3-to-epub3"
                name="main">
    
    <p:input port="epub.in.fileset" primary="true"/>
    <p:input port="epub.in.in-memory" sequence="true"/>
    
    <p:output port="epub.out.fileset" primary="true"/>
    <p:output port="epub.out.in-memory" sequence="true">
        <p:pipe step="update-container" port="in-memory"/>
    </p:output>
    
    <p:option name="result-base" required="true"/>
    <p:option name="braille-translator" required="true" />
    <p:option name="stylesheet" required="true"/>
    <p:option name="apply-document-specific-stylesheets" required="true"/>
    <p:option name="set-default-rendition-to-braille" required="true"/>
    <p:option name="content-media-types" select="'application/xhtml+xml'">
        <!--
            space separated list of content document media-types to include in the braille rendition
        -->
    </p:option>
    
    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl">
        <p:documentation>
            px:error
            px:message
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/file-utils/library.xpl">
        <p:documentation>
            px:set-base-uri
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl">
        <p:documentation>
            px:fileset-create
            px:fileset-add-entry
            px:fileset-join
            px:fileset-rebase
            px:fileset-copy
            px:fileset-load
            px:fileset-filter
            px:fileset-update
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/epub-utils/library.xpl">
        <p:documentation>
            px:epub-update-links
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/common-utils/library.xpl">
        <p:documentation>
            px:transform
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/css-utils/library.xpl">
        <p:documentation>
            px:css-cascade
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/css-utils/library.xpl">
        <p:documentation>
            css:apply-stylesheets
            css:delete-stylesheets
            css:extract
        </p:documentation>
    </p:import>
    
    <p:variable name="default-stylesheet" select="resolve-uri('../css/default.css')">
        <p:inline>
            <irrelevant/>
        </p:inline>
    </p:variable>
    
    <p:identity>
        <p:input port="source">
            <p:pipe step="main" port="epub.in.fileset"/>
        </p:input>
    </p:identity>
    
    <!--
        Make sure that the base uri of the fileset is the directory containing the mimetype
        file. This will normally also eliminate any relative hrefs starting with "..", which is
        needed because px:fileset-copy errors when it encounters these.
    -->
    <p:choose>
        <p:when test="//d:file[matches(@href,'^(.+/)?mimetype$')]">
            <px:fileset-rebase>
                <p:with-option name="new-base"
                               select="//d:file[matches(@href,'^(.+/)?mimetype$')][1]
                                       /replace(resolve-uri(@href,base-uri(.)),'mimetype$','')"/>
            </px:fileset-rebase>
        </p:when>
        <p:otherwise>
            <px:error code="XXXXX" message="Fileset must contain a 'mimetype' file"/>
        </p:otherwise>
    </p:choose>
    
    <!--
        copy EPUB to new location
    -->
    
    <px:fileset-copy name="move">
        <p:with-option name="target" select="$result-base"/>
        <p:input port="source.in-memory">
            <p:pipe step="main" port="epub.in.in-memory"/>
        </p:input>
    </px:fileset-copy>
    
    <!--
        load default rendition package document
    -->
    <px:fileset-filter media-types="application/oebps-package+xml"/>
    <p:delete match="d:file[preceding::d:file]"/>
    <px:fileset-load name="default-rendition.package-document">
        <p:input port="in-memory">
            <p:pipe step="move" port="result.in-memory"/>
        </p:input>
    </px:fileset-load>
    
    <!--
        create braille rendition file set
    -->
    
    <p:group name="braille-rendition.fileset">
        <p:output port="fileset" primary="true"/>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="apply" port="result.in-memory"/>
        </p:output>
        <p:output port="mapping">
            <p:pipe step="mapping" port="result"/>
        </p:output>
        <p:xslt name="mapping">
            <p:input port="stylesheet">
                <p:document href="braille-rendition.fileset.xsl"/>
            </p:input>
            <p:with-param name="content-media-types" select="$content-media-types"/>
            <p:with-param name="braille-rendition.package-document.base"
                          select="resolve-uri('EPUB/package-braille.opf',$result-base)"/>
        </p:xslt>
        <p:sink/>
        <!--
            update cross references
        -->
        <px:epub-update-links name="update-links">
            <p:input port="source.fileset">
                <p:pipe step="move" port="result.fileset"/>
            </p:input>
            <p:input port="source.in-memory">
                <p:pipe step="move" port="result.in-memory"/>
            </p:input>
            <p:input port="mapping">
                <p:pipe step="mapping" port="result"/>
            </p:input>
        </px:epub-update-links>
        <!--
            perform rename
        -->
        <px:fileset-apply name="apply">
            <p:input port="source.in-memory">
                <p:pipe step="update-links" port="result.in-memory"/>
            </p:input>
            <p:input port="mapping">
                <p:pipe step="mapping" port="result"/>
            </p:input>
        </px:fileset-apply>
    </p:group>
    
    <!--
        process braille rendition xhtml documents
    -->
    
    <p:group name="braille-rendition.process-html">
        <p:output port="result.fileset" primary="true"/>
        <p:output port="result.in-memory" sequence="true">
            <p:pipe step="update-fileset" port="result.in-memory"/>
        </p:output>
        <p:output port="html.fileset">
            <p:pipe step="load" port="result.fileset"/>
        </p:output>
        <p:output port="html.in-memory" sequence="true">
            <p:pipe step="for-each" port="html"/>
        </p:output>
        <p:output port="css.fileset">
            <p:pipe step="css.fileset" port="result"/>
        </p:output>
        <p:output port="css.in-memory" sequence="true">
            <p:pipe step="for-each" port="css"/>
        </p:output>
        <px:fileset-load name="load">
            <p:input port="in-memory">
                <p:pipe step="braille-rendition.fileset" port="in-memory"/>
            </p:input>
            <p:with-option name="media-types" select="$content-media-types"/>
        </px:fileset-load>
        <p:for-each name="for-each">
            <p:output port="html" primary="true"/>
            <p:output port="css" sequence="true">
                <p:pipe step="extract-css" port="css"/>
            </p:output>
            <p:variable name="lang" select="(/*/opf:metadata/dc:language[not(@refines)])[1]/text()">
                <p:pipe port="result" step="default-rendition.package-document"/>
            </p:variable>
            <px:message message="Generating $1" severity="INFO">
                <p:with-option name="param1" select="substring-after(base-uri(/*),'!/')"/>
            </px:message>
            <p:choose>
                <p:when test="$apply-document-specific-stylesheets='true'">
                    <px:message severity="DEBUG" message="Inlining document-specific CSS"/>
                    <css:apply-stylesheets>
                        <p:input port="context">
                            <p:pipe step="move" port="result.in-memory"/>
                        </p:input>
                    </css:apply-stylesheets>
                </p:when>
                <p:otherwise>
                    <p:delete match="@style"/>
                </p:otherwise>
            </p:choose>
            <css:delete-stylesheets/>
            <px:css-cascade media="embossed">
                <p:with-option name="default-stylesheet" select="($stylesheet,$default-stylesheet)[not(.='')][1]"/>
            </px:css-cascade>
            <px:transform name="transform">
                <p:with-option name="query" select="concat('(input:html)(input:css)(output:html)(output:css)(output:braille)',
                                                           $braille-translator,
                                                           '(locale:',$lang,')')"/>
            </px:transform>
            <p:group name="extract-css">
                <p:output port="result" primary="true">
                    <p:pipe step="extract-css.result" port="result"/>
                </p:output>
                <p:output port="css" sequence="true">
                    <p:pipe step="css" port="result"/>
                </p:output>
                <css:extract name="extract"/>
                <p:delete match="@style" name="without-css"/>
                <p:choose>
                    <p:xpath-context>
                        <p:pipe step="extract" port="stylesheet"/>
                    </p:xpath-context>
                    <p:when test="normalize-space(string(/*))=''">
                        <p:identity/>
                    </p:when>
                    <p:otherwise>
                        <p:add-attribute match="/html:link" attribute-name="href" name="css-link">
                            <p:input port="source">
                                <p:inline xmlns="http://www.w3.org/1999/xhtml">
                                    <link rel="stylesheet" type="text/css" media="embossed"/>
                                </p:inline>
                            </p:input>
                            <p:with-option name="attribute-value" select="replace(base-uri(/*),'^.*/(([^/]+)\.x?html|([^/]+))$','$2$3.css')"/>
                        </p:add-attribute>
                        <!--
                            assuming there is one and only one head element
                        -->
                        <p:insert match="html:head" position="last-child">
                            <p:input port="source">
                                <p:pipe step="without-css" port="result"/>
                            </p:input>
                            <p:input port="insertion">
                                <p:pipe step="css-link" port="result"/>
                            </p:input>
                        </p:insert>
                    </p:otherwise>
                </p:choose>
                <p:identity name="extract-css.result"/>
                <p:identity>
                    <p:input port="source">
                        <p:pipe step="extract" port="stylesheet"/>
                    </p:input>
                </p:identity>
                <p:choose>
                    <p:when test="normalize-space(string(/*))=''">
                        <p:identity>
                            <p:input port="source">
                                <p:empty/>
                            </p:input>
                        </p:identity>
                    </p:when>
                    <p:otherwise>
                        <px:set-base-uri>
                            <!--
                                using "base-uri(parent::*)" because link has the base-uri of this XProc file
                            -->
                            <p:with-option name="base-uri"
                                           select="//html:link[@rel='stylesheet' and @type='text/css' and @media='embossed']
                                                   /resolve-uri(@href,base-uri(parent::*))">
                                <p:pipe step="extract-css.result" port="result"/>
                            </p:with-option>
                        </px:set-base-uri>
                    </p:otherwise>
                </p:choose>
                <p:identity name="css"/>
            </p:group>
        </p:for-each>
        <p:sink/>
        <!--
            extracted css fileset
        -->
        <px:fileset-create name="base"/>
        <p:for-each>
            <p:iteration-source>
                <p:pipe step="for-each" port="css"/>
            </p:iteration-source>
            <px:fileset-add-entry>
                <p:input port="source">
                    <p:pipe step="base" port="result"/>
                </p:input>
                <p:with-option name="href" select="base-uri(/*)"/>
                <p:with-option name="media-type" select="/c:result/@content-type"/> <!-- text/plain -->
            </px:fileset-add-entry>
        </p:for-each>
        <px:fileset-join name="css.fileset"/>
        <p:sink/>
        <!--
            update braille rendition fileset
        -->
        <px:fileset-join>
            <p:input port="source">
                <p:pipe step="braille-rendition.fileset" port="fileset"/>
                <p:pipe step="css.fileset" port="result"/>
            </p:input>
        </px:fileset-join>
        <px:fileset-update name="update-fileset">
            <p:input port="source.in-memory">
                <p:pipe step="braille-rendition.fileset" port="in-memory"/>
                <p:pipe step="for-each" port="css"/>
            </p:input>
            <p:input port="update.fileset">
                <p:pipe step="load" port="result.fileset"/>
            </p:input>
            <p:input port="update.in-memory">
                <p:pipe step="for-each" port="html"/>
            </p:input>
        </px:fileset-update>
    </p:group>
    
    <!--
        process braille rendition package document
    -->
    
    <p:group name="braille-rendition.process-package-doc">
        <p:output port="fileset" primary="true"/>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="update-fileset" port="result.in-memory"/>
        </p:output>
        <px:fileset-load media-types="application/oebps-package+xml" name="copied-package-doc">
            <p:input port="in-memory">
                <p:pipe step="braille-rendition.process-html" port="result.in-memory"/>
            </p:input>
        </px:fileset-load>
        <p:sink/>
        <!--
            change dc:language and dcterms:modified, and add extracted css files
        -->
        <p:xslt name="package-doc">
            <p:input port="source">
                <p:pipe step="copied-package-doc" port="result"/>
                <p:pipe step="braille-rendition.process-html" port="css.fileset"/>
                <p:pipe step="braille-rendition.process-html" port="html.in-memory"/>
            </p:input>
            <p:input port="stylesheet">
                <p:document href="braille-rendition.package-document.xsl"/>
            </p:input>
            <p:input port="parameters">
                <p:empty/>
            </p:input>
        </p:xslt>
        <p:sink/>
        <px:fileset-update name="update-fileset">
            <p:input port="source.fileset">
                <p:pipe step="braille-rendition.process-html" port="result.fileset"/>
            </p:input>
            <p:input port="source.in-memory">
                <p:pipe step="braille-rendition.process-html" port="result.in-memory"/>
            </p:input>
            <p:input port="update.fileset">
                <p:pipe step="copied-package-doc" port="result.fileset"/>
            </p:input>
            <p:input port="update.in-memory">
                <p:pipe step="package-doc" port="result"/>
            </p:input>
        </px:fileset-update>
    </p:group>
    
    <!--
        final braille rendition package document
    -->
    <px:fileset-load media-types="application/oebps-package+xml" name="braille-rendition.package-document">
        <p:input port="in-memory">
            <p:pipe step="braille-rendition.process-package-doc" port="in-memory"/>
        </p:input>
    </px:fileset-load>
    <p:sink/>
    
    <!--
        add braille rendition
    -->
    
    <p:group name="add-braille-rendition">
        <p:output port="fileset" primary="true"/>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="move" port="result.in-memory"/>
            <p:pipe step="braille-rendition.process-package-doc" port="in-memory"/>
        </p:output>
        <px:fileset-join>
            <p:input port="source">
                <p:pipe step="move" port="result.fileset"/>
                <p:pipe step="braille-rendition.process-package-doc" port="fileset"/>
            </p:input>
        </px:fileset-join>
    </p:group>
    
    <!--
        create and add metadata.xml
    -->
    
    <p:group name="add-metadata">
        <p:output port="fileset" primary="true">
            <p:pipe step="add-entry" port="result"/>
        </p:output>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="add-entry" port="result.in-memory"/>
        </p:output>
        <px:fileset-add-entry name="add-entry">
            <p:input port="source.in-memory">
                <p:pipe step="add-braille-rendition" port="in-memory"/>
            </p:input>
            <p:input port="entry">
                <p:pipe step="metadata" port="result"/>
            </p:input>
        </px:fileset-add-entry>
        <p:sink/>
        <p:group name="metadata">
            <p:output port="result"/>
            <p:identity>
                <p:input port="source">
                    <p:inline xmlns="http://www.idpf.org/2007/opf">
<metadata xmlns:dcterms="http://purl.org/dc/terms/"/></p:inline>
                </p:input>
            </p:identity>
            <p:add-attribute match="/opf:metadata" attribute-name="unique-identifier">
                <p:with-option name="attribute-value" select="/opf:package/@unique-identifier">
                    <p:pipe step="braille-rendition.package-document" port="result"/>
                </p:with-option>
            </p:add-attribute>
            <p:insert match="/opf:metadata" position="last-child">
                <p:input port="insertion" select="for $unique-identifier in /opf:package/@unique-identifier
                                                  return /opf:package/opf:metadata/dc:identifier[@id=$unique-identifier]">
                    <p:pipe step="braille-rendition.package-document" port="result"/>
                </p:input>
            </p:insert>
            <p:insert match="/opf:metadata" position="last-child">
                <p:input port="insertion" select="/opf:package/opf:metadata/opf:meta[@property='dcterms:modified']">
                    <p:pipe step="braille-rendition.package-document" port="result"/>
                </p:input>
            </p:insert>
            <px:set-base-uri>
                <p:with-option name="base-uri" select="resolve-uri('META-INF/metadata.xml',$result-base)"/>
            </px:set-base-uri>
        </p:group>
        <p:sink/>
    </p:group>
    
    <!--
        create and add rendition mapping document
    -->
    <p:group name="add-rendition-mapping">
        <p:output port="fileset" primary="true">
            <p:pipe step="add-entry" port="result"/>
        </p:output>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="add-entry" port="result.in-memory"/>
        </p:output>
        <px:fileset-add-entry name="add-entry">
            <p:input port="source.in-memory">
                <p:pipe step="add-metadata" port="in-memory"/>
            </p:input>
            <p:input port="entry">
                <p:pipe step="rendition-mapping" port="result"/>
            </p:input>
            <p:with-param port="file-attributes" name="indent" select="'true'"/>
        </px:fileset-add-entry>
        <p:sink/>
        <p:group name="rendition-mapping">
            <p:output port="result"/>
            <p:for-each name="resource-maps">
                <p:iteration-source select="/*/d:file">
                    <p:pipe step="braille-rendition.process-html" port="html.fileset"/>
                </p:iteration-source>
                <p:output port="result"/>
                <p:variable name="braille-rendition.html.base" select="/d:file/resolve-uri(@href,base-uri(.))"/>
                <p:variable name="default-rendition.html.base"
                            select="//d:file[resolve-uri(@href,base-uri(.))=$braille-rendition.html.base]
                                    /resolve-uri(@original-href,base-uri(.))">
                    <p:pipe step="braille-rendition.fileset" port="mapping"/>
                </p:variable>
                <p:xslt template-name="main">
                    <p:input port="stylesheet">
                        <p:document href="resource-map.xsl"/>
                    </p:input>
                    <p:input port="source">
                        <p:pipe step="default-rendition.package-document" port="result"/>
                        <p:pipe step="braille-rendition.package-document" port="result"/>
                    </p:input>
                    <p:with-param name="default-rendition.html.base" select="$default-rendition.html.base"/>
                    <p:with-param name="braille-rendition.html.base" select="$braille-rendition.html.base"/>
                    <p:with-param name="rendition-mapping.base" select="resolve-uri('EPUB/renditionMapping.html',$result-base)"/>
                </p:xslt>
            </p:for-each>
            <p:sink/>
            <p:insert match="//html:nav" position="last-child">
                <p:input port="source">
                    <p:inline xmlns="http://www.w3.org/1999/xhtml">
<html>
   <head>
      <meta charset="utf-8"/>
   </head>
   <body>
      <nav epub:type="resource-map"/>
   </body>
</html></p:inline>
                </p:input>
                <p:input port="insertion" select="/html:nav[@epub:type='resource-map']/*">
                    <p:pipe step="resource-maps" port="result"/>
                </p:input>
            </p:insert>
            <px:set-base-uri>
                <p:with-option name="base-uri" select="resolve-uri('EPUB/renditionMapping.html',$result-base)"/>
            </px:set-base-uri>
        </p:group>
        <p:sink/>
    </p:group>
    
    <!--
        update container.xml
    -->
    
    <p:group name="update-container">
        <p:output port="fileset" primary="true">
            <p:pipe step="update-fileset" port="result.fileset"/>
        </p:output>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="update-fileset" port="result.in-memory"/>
        </p:output>
        <px:fileset-update name="update-fileset">
            <p:input port="source.in-memory">
                <p:pipe step="add-rendition-mapping" port="in-memory"/>
            </p:input>
            <p:input port="update.fileset">
                <p:pipe step="original-container" port="result.fileset"/>
            </p:input>
            <p:input port="update.in-memory">
                <p:pipe step="container" port="result"/>
            </p:input>
        </px:fileset-update>
        <p:sink/>
        <px:fileset-load name="original-container">
            <p:input port="fileset">
                <p:pipe step="add-rendition-mapping" port="fileset"/>
            </p:input>
            <p:input port="in-memory">
                <p:pipe step="add-rendition-mapping" port="in-memory"/>
            </p:input>
            <p:with-option name="href" select="resolve-uri('META-INF/container.xml',$result-base)"/>
        </px:fileset-load>
        <p:group name="container">
            <p:output port="result"/>
            <p:insert match="/ocf:container/ocf:rootfiles">
                <p:input port="insertion">
                    <p:inline xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
                        <rootfile full-path="EPUB/package-braille.opf" media-type="application/oebps-package+xml"
                                  rendition:accessMode="tactile" rendition:label="Pre-translated to braille"/>
                    </p:inline>
                </p:input>
                <p:with-option name="position" select="if ($set-default-rendition-to-braille='true') then 'first-child' else 'last-child'"/>
            </p:insert>
            <p:add-attribute match="/ocf:container/ocf:rootfiles/ocf:rootfile[last()]" attribute-name="rendition:language">
                <p:with-option name="attribute-value" select="/opf:package/opf:metadata/dc:language[1]/string(.)">
                    <p:pipe step="braille-rendition.package-document" port="result"/>
                </p:with-option>
            </p:add-attribute>
            <p:add-attribute match="/ocf:container/ocf:rootfiles/ocf:rootfile[last()]" attribute-name="rendition:layout">
                <p:with-option name="attribute-value"
                               select="(/opf:package/opf:metadata/opf:meta[@property='rendition:layout']/string(.),'reflowable')[1]">
                    <p:pipe step="braille-rendition.package-document" port="result"/>
                </p:with-option>
            </p:add-attribute>
            <p:insert position="last-child" match="/ocf:container">
                <p:input port="insertion">
                    <p:inline xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
                        <link href="EPUB/renditionMapping.html" rel="mapping" media-type="application/xhtml+xml"/>
                    </p:inline>
                </p:input>
            </p:insert>
            <px:set-base-uri>
                <p:with-option name="base-uri" select="resolve-uri('META-INF/container.xml',$result-base)"/>
            </px:set-base-uri>
        </p:group>
        <p:sink/>
    </p:group>
    
</p:declare-step>
