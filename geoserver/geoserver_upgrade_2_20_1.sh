# Notes when upgrading to geoserver 2.20.x, some troubles and how to fix it.
# MBtiles-plugin
# unzip geoserver-2.20-SNAPSHOT-mbtiles-plugin.zip #download from https://build.geoserver.org/geoserver/2.20.x/community-latest/
# in /usr/share/geoserver/webapps/geoserver/WEB-INF/lib, and encounter
# org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'mbtilesProcess' defined in URL
# https://stackoverflow.com/questions/34149778/cant-install-mbtiles-plugin-in-geoserver

# first, import wps plugin
unzip geoserver-2.20.1-wps-plugin.zip 
unzip geoserver-2.20-SNAPSHOT-mbtiles-plugin.zip
unzip geoserver-2.20-SNAPSHOT-mbtiles-store-plugin.zip
# https://github.com/xerial/sqlite-jdbc/releases
wget https://github.com/xerial/sqlite-jdbc/releases/download/3.36.0.3/sqlite-jdbc-3.36.0.3.jar
# remove original sqlite-jdbc-3.34.0.jar
mv sqlite-jdbc-3.34.0.jar ~/tmp/
# done

# Exclude GeoPkg (GeoPackage) plugin, i.e. geoserver-2.20-SNAPSHOT-geopkg-plugin.zip
# cause error: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'geopkgProcess'
# see mailing list (still NOT solved yet)
# https://www.mail-archive.com/geoserver-users@lists.sourceforge.net/msg35205.html


# Other problems
# Password, recorded in 
# /usr/share/geoserver/data_dir/security/usergroup/default/users.xml

# CORS
# nano /usr/share/geoserver/webapps/geoserver/WEB-INF/web.xml, search cross-origin
# uncomment and enable CORS in Jetty
```
    <filter>
      <filter-name>cross-origin</filter-name>
      <filter-class>org.eclipse.jetty.servlets.CrossOriginFilter</filter-class>
      <init-param>
        <param-name>chainPreflight</param-name>
        <param-value>false</param-value>
      </init-param>
      <init-param>
        <param-name>allowedOrigins</param-name>
        <param-value>*</param-value>
      </init-param>
      <init-param>
        <param-name>allowedMethods</param-name>
        <param-value>GET,POST,PUT,DELETE,HEAD,OPTIONS</param-value>
      </init-param>
      <init-param>
        <param-name>allowedHeaders</param-name>
        <param-value>*</param-value>
      </init-param>
    </filter>
```    

#   <!-- Uncomment following filter to enable CORS-->
```
    <filter-mapping>
        <filter-name>cross-origin</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>
```

