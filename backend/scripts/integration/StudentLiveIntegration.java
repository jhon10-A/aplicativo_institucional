import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.sql.*;
import java.time.*;
import java.util.*;
import java.net.URI;
import java.net.http.*;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.server.context.WebServerApplicationContext;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.JsonNode;
import pe.edu.micaelabastidas.backend.BackendApplication;

/** Explicitly opt-in live fixture runner. Never deletes, updates or performs DDL.
 * Credentials, IDs and attachments go only to the ignored private run directory.
 * Requires Java 21, compiled backend classes and the Maven dependency classpath.
 */
public class StudentLiveIntegration {
    static final ObjectMapper JSON = new ObjectMapper();
    static final String URL = "jdbc:mysql://localhost:3307/db_institucional";
    static final Map<String,List<Long>> ids = new LinkedHashMap<>();
    static final List<String> results = new ArrayList<>();
    static Path dir;
    static Connection db;
    static HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    static String base;
    static int checks;
    static void require(boolean condition, String message) {if(!condition) throw new IllegalStateException(message);}
    static void save(String name,Object value) throws Exception {Files.writeString(dir.resolve(name),JSON.writeValueAsString(value));}
    static long insert(String table,String columns,Object... values) throws Exception {
        String marks=String.join(",",Collections.nCopies(values.length,"?"));
        try(var p=db.prepareStatement("INSERT INTO "+table+" ("+columns+") VALUES ("+marks+")",Statement.RETURN_GENERATED_KEYS)) {
            for(int i=0;i<values.length;i++)p.setObject(i+1,values[i]);
            require(p.executeUpdate()==1,"Insert failed: "+table);
            long id;
            try(var r=p.getGeneratedKeys()){require(r.next(),"Missing ID");id=r.getLong(1);}
            ids.computeIfAbsent(table,k->new ArrayList<>()).add(id);
            save("ids.json",ids); // journal before commit: rolled-back IDs are labelled in state.txt
            return id;
        }
    }
    static void role(long user,String role) throws Exception {
        try(var p=db.prepareStatement("INSERT INTO usuario_rol (usuario_id,rol_id) SELECT ?,id FROM rol WHERE nombre=?")) {
            p.setLong(1,user);p.setString(2,role);require(p.executeUpdate()==1,"Role missing");
        }
    }
    static String schema() throws Exception {
        StringBuilder s=new StringBuilder();
        try(var p=db.createStatement();var r=p.executeQuery("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME")) {
            List<String> tables=new ArrayList<>();while(r.next())tables.add(r.getString(1));
            require(tables.size()==25,"Expected exactly 25 tables");
            for(String table:tables)try(var q=db.createStatement();var t=q.executeQuery("SHOW CREATE TABLE "+table)){t.next();s.append(t.getString(2).replaceAll(" AUTO_INCREMENT=\\d+", ""));}
        }
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(s.toString().getBytes(StandardCharsets.UTF_8)));
    }
    static Map<String,String> originals() throws Exception {
        Map<String,String> result=new TreeMap<>();
        // Preserve all pre-existing rows, including composite PKs. No values are printed.
        for(String table:List.of("usuario","rol","usuario_rol")) {
            String where=table.equals("usuario")?" WHERE id NOT IN ("+newUsers()+")":table.equals("usuario_rol")?" WHERE usuario_id NOT IN ("+newUsers()+")":"";
            StringBuilder text=new StringBuilder();
            try(var p=db.createStatement();var r=p.executeQuery("SELECT * FROM "+table+where+" ORDER BY 1,2")) {
                while(r.next())for(int i=1;i<=r.getMetaData().getColumnCount();i++)text.append(Objects.toString(r.getObject(i),"<null>")).append('\0');
            }
            result.put(table,HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(text.toString().getBytes(StandardCharsets.UTF_8))));
        }
        return result;
    }
    static String newUsers(){return ids.getOrDefault("usuario",List.of(0L)).stream().map(Object::toString).collect(java.util.stream.Collectors.joining(","));}
    static HttpResponse<byte[]> request(String method,String path,String token,byte[] body,String type,int expected) throws Exception {
        var b=HttpRequest.newBuilder(URI.create(base+path)).timeout(Duration.ofSeconds(15)).header("Origin","http://localhost:5174");
        if(token!=null)b.header("Authorization","Bearer "+token);
        if(type!=null)b.header("Content-Type",type);
        var response=http.send(b.method(method,body==null?HttpRequest.BodyPublishers.noBody():HttpRequest.BodyPublishers.ofByteArray(body)).build(),HttpResponse.BodyHandlers.ofByteArray());
        require(response.statusCode()==expected,method+" "+path+" expected "+expected+" got "+response.statusCode());
        checks++;results.add(method+" "+path+" -> "+expected);save("http-results.json",results);
        return response;
    }
    static JsonNode get(String path,String token,int status) throws Exception {return JSON.readTree(request("GET",path,token,null,null,status).body());}
    static String login(String name,String password) throws Exception {
        byte[] body=JSON.writeValueAsBytes(Map.of("nombreUsuario",name,"password",password));
        return JSON.readTree(request("POST","/api/auth/login",null,body,"application/json",200).body()).path("accessToken").asText();
    }
    static HttpResponse<byte[]> submit(String path,String token,String filename,byte[] content,int status) throws Exception {
        String boundary="student-live-boundary";
        byte[] header=("--"+boundary+"\r\nContent-Disposition: form-data; name=\"comentario\"\r\n\r\nTEST_EST: respuesta ficticia autorizada\r\n--"+boundary+"\r\nContent-Disposition: form-data; name=\"archivo\"; filename=\""+filename+"\"\r\nContent-Type: text/plain\r\n\r\n").getBytes(StandardCharsets.UTF_8);
        var out=new java.io.ByteArrayOutputStream();out.write(header);out.write(content);out.write(("\r\n--"+boundary+"--\r\n").getBytes(StandardCharsets.UTF_8));
        return request("POST",path,token,out.toByteArray(),"multipart/form-data; boundary="+boundary,status);
    }
    public static void main(String[] args) throws Exception {
        require("AUTHORIZED_NEW_TEST_RECORDS_3307".equals(System.getenv("LIVE_TEST_AUTHORIZE")),"Explicit write authorization required");
        dir=Path.of(System.getenv("LIVE_TEST_DIRECTORY")).toAbsolutePath();
        require(dir.startsWith(Path.of("../secrets/student-live").toAbsolutePath().normalize()),"Private directory required");
        boolean resume="VERIFY_COMMITTED_FIXTURE_ONLY".equals(System.getenv("LIVE_TEST_RESUME"));
        Files.createDirectories(dir);require(resume==Files.exists(dir.resolve("ids.json")),"Existing run; never reseed automatically");
        Path backup=Path.of(System.getenv("LIVE_TEST_BACKUP"));
        require(Files.isRegularFile(backup),"Backup missing");
        String hash=HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(Files.readAllBytes(backup)));
        String expectedHash=System.getenv("LIVE_TEST_BACKUP_SHA256");
        require(expectedHash!=null&&expectedHash.matches("[a-fA-F0-9]{64}")&&hash.equalsIgnoreCase(expectedHash),"Backup integrity mismatch");
        if(!resume)Files.writeString(dir.resolve("state.txt"),"BACKUP_VERIFIED; NOT_STARTED");
        try(var connection=DriverManager.getConnection(URL,System.getenv("SPRING_DATASOURCE_USERNAME"),System.getenv("SPRING_DATASOURCE_PASSWORD"))) {
            db=connection;
            try(var p=db.createStatement();var r=p.executeQuery("SELECT DATABASE(),@@port")){r.next();require("db_institucional".equals(r.getString(1))&&r.getInt(2)==3307,"Wrong database");}
            String schemaBefore=schema();var originalBefore=originals();
            // Stop if other academic records appeared since the reviewed backup.
            try(var p=db.createStatement();var r=p.executeQuery("SELECT TABLE_NAME,TABLE_TYPE,ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE()")) {
                while(r.next())require("BASE TABLE".equals(r.getString(2))&&"InnoDB".equals(r.getString(3)),"Transactional tables required");
            }
            if(!resume)for(String table:List.of("estudiante","matricula","curso","tarea","docente","calificacion","asistencia","comunicado"))
                try(var p=db.createStatement();var r=p.executeQuery("SELECT COUNT(*) FROM "+table)){r.next();require(r.getLong(1)==0,"Existing academic data changed; review required");}
            System.out.println("LIVE_BACKUP_AND_TARGET_VERIFIED=true");
            String run="TEST_EST_"+UUID.randomUUID().toString().substring(0,8);
            String password=Base64.getUrlEncoder().withoutPadding().encodeToString(new SecureRandom().generateSeed(24));
            if(!resume)save("credentials.json",Map.of("usernameA",run+"_A","usernameB",run+"_B","password",password,"baseUrl","http://localhost:8081"));
            long[] users=new long[3],students=new long[2],sections=new long[2],enrollments=new long[2],assignments=new long[2],tasks=new long[2],grades=new long[2],attendance=new long[2],notices=new long[2];long expired;
            if(!resume){db.setAutoCommit(false);
            try {
                String encoded=new BCryptPasswordEncoder(12).encode(password);
                for(int i=0;i<3;i++){users[i]=insert("usuario","nombre_usuario,password_hash,nombres,apellidos,activo",run+"_"+(i==0?"A":i==1?"B":"DOC"),encoded,"TEST_EST",run+"_"+i,true);role(users[i],i==2?"DOCENTE":"ESTUDIANTE");}
                for(int i=0;i<2;i++)students[i]=insert("estudiante","usuario_id,codigo_estudiante",users[i],run+"_"+i);
                long teacher=insert("docente","usuario_id,especialidad",users[2],run);
                long period=insert("periodo_academico","nombre,fecha_inicio,fecha_fin,activo",run,LocalDate.now().withDayOfYear(1),LocalDate.now().withMonth(12).withDayOfMonth(31),true);
                long grade=insert("grado","nivel,nombre","SECUNDARIA",run);
                long course=insert("curso","nombre,descripcion,activo",run+" Curso",run+": datos ficticios",true);
                LocalDateTime now;
                try(var p=db.createStatement();var r=p.executeQuery("SELECT CURRENT_TIMESTAMP")){r.next();now=r.getObject(1,LocalDateTime.class);}
                for(int i=0;i<2;i++) {
                    sections[i]=insert("seccion","grado_id,nombre",grade,i==0?"TEST_A":"TEST_B");
                    enrollments[i]=insert("matricula","estudiante_id,periodo_academico_id,seccion_id,fecha_matricula,estado",students[i],period,sections[i],now.toLocalDate(),"ACTIVA");
                    assignments[i]=insert("asignacion_docente","docente_id,curso_id,periodo_academico_id,seccion_id",teacher,course,period,sections[i]);
                    tasks[i]=insert("tarea","asignacion_docente_id,titulo,descripcion,fecha_publicacion,fecha_limite,activo",assignments[i],run+" Tarea "+i,run,now.minusDays(1),now.plusDays(7),true);
                    grades[i]=insert("calificacion","matricula_id,asignacion_docente_id,periodo_academico_id,seccion_id,etapa,concepto,nota",enrollments[i],assignments[i],period,sections[i],"TEST",run,i==0?16:0);
                    for(int j=0;j<4;j++){long id=insert("asistencia","matricula_id,asignacion_docente_id,periodo_academico_id,seccion_id,fecha,estado,observacion",enrollments[i],assignments[i],period,sections[i],now.toLocalDate().minusDays(j),List.of("PRESENTE","FALTA","TARDANZA","JUSTIFICADA").get(j),run);if(j==0)attendance[i]=id;}
                    notices[i]=insert("comunicado","autor_id,titulo,contenido,seccion_destino_id,publicado_en,activo",users[2],run+" Seccion "+i,run,sections[i],now.minusDays(1),true);
                }
                expired=insert("tarea","asignacion_docente_id,titulo,fecha_publicacion,fecha_limite,activo",assignments[0],run+" Vencida",now.minusDays(3),now.minusDays(1),true);
                insert("comunicado","autor_id,titulo,contenido,publicado_en,activo",users[2],run+" General",run,now.minusDays(1),true);
                insert("comunicado","autor_id,titulo,contenido,publicado_en,activo",users[2],run+" Futuro",run,now.plusDays(1),true);
                insert("comunicado","autor_id,titulo,contenido,publicado_en,fecha_vencimiento,activo",users[2],run+" Vencido",run,now.minusDays(2),now.minusDays(1),true);
                save("fixture.json",Map.of("marker",run,"enrollments",enrollments,"assignments",assignments,"tasks",tasks,"grades",grades,"attendance",attendance,"notices",notices));
                db.commit();Files.writeString(dir.resolve("state.txt"),"FIXTURES_COMMITTED");
            } catch(Exception e){db.rollback();Files.writeString(dir.resolve("state.txt"),"FIXTURES_ROLLED_BACK; journal IDs not committed");throw e;}
            db.setAutoCommit(true);
            require(schemaBefore.equals(schema()),"Schema changed");require(originalBefore.equals(originals()),"Original records changed");
            } else {
                var journal=JSON.readTree(Files.readString(dir.resolve("ids.json")));
                for(String table:List.of("usuario","estudiante","docente","periodo_academico","grado","curso","seccion","matricula","asignacion_docente","tarea","calificacion","asistencia","comunicado","entrega_tarea")) {
                    if(journal.has(table)){List<Long> entries=new ArrayList<>();for(var id:journal.path(table))entries.add(id.asLong());ids.put(table,entries);}
                }
                require(!ids.containsKey("entrega_tarea"),"Deliveries already created; do not repeat writes");
                var f=JSON.readTree(Files.readString(dir.resolve("fixture.json")));
                run=f.path("marker").asText();password=JSON.readTree(Files.readString(dir.resolve("credentials.json"))).path("password").asText();
                for(int i=0;i<3;i++)users[i]=ids.get("usuario").get(i);
                for(int i=0;i<2;i++){enrollments[i]=f.path("enrollments").get(i).asLong();assignments[i]=f.path("assignments").get(i).asLong();tasks[i]=f.path("tasks").get(i).asLong();grades[i]=f.path("grades").get(i).asLong();attendance[i]=f.path("attendance").get(i).asLong();notices[i]=f.path("notices").get(i).asLong();}
                expired=ids.get("tarea").get(2);
                originalBefore=originals();
                // Compare the actual table definitions with the preserved pre-insert backup.
                String dump=Files.readString(backup);
                var matcher=java.util.regex.Pattern.compile("(?ms)^CREATE TABLE `([^`]+)` \\(.*?^\\) ENGINE=[^;]+;").matcher(dump);
                Map<String,String> definitions=new TreeMap<>();
                while(matcher.find())definitions.put(matcher.group(1),matcher.group().replaceAll(" AUTO_INCREMENT=\\d+", "").replaceFirst(";$", ""));
                require(definitions.size()==25,"Incomplete backup schema");
                for(var entry:definitions.entrySet())try(var p=db.createStatement();var r=p.executeQuery("SHOW CREATE TABLE "+entry.getKey())){r.next();require(entry.getValue().equals(r.getString(2).replaceAll(" AUTO_INCREMENT=\\d+", "")),"Actual schema differs from backup: "+entry.getKey());}
                System.out.println("LIVE_SCHEMA_MATCHES_BACKUP=true");
            }
            System.out.println("LIVE_FIXTURES_COMMITTED="+run);
            try(var context=new SpringApplicationBuilder(BackendApplication.class).run("--server.address=127.0.0.1","--server.port=8081","--spring.config.import=","--spring.profiles.active=student-live-test","--spring.datasource.url="+URL,"--spring.datasource.hikari.read-only=false","--app.dev.seed-enabled=false","--spring.jpa.hibernate.ddl-auto=validate","--spring.sql.init.mode=never","--spring.jpa.show-sql=false","--logging.level.root=ERROR","--spring.main.banner-mode=off","--app.cors.allowed-origin=http://localhost:5174","--app.submissions.storage="+dir.resolve("attachments"))) {
                base="http://127.0.0.1:"+((WebServerApplicationContext)context).getWebServer().getPort();
                String[] tokens={login(run+"_A",password),login(run+"_B",password)};
                byte[] file=(run+": archivo ficticio autorizado\n").getBytes(StandardCharsets.UTF_8);
                for(int i=0;i<2;i++) {
                    String token=tokens[i],prefix="/api/estudiante/matriculas/"+enrollments[i];
                    get("/api/estudiante/perfil",token,200);get("/api/estudiante/matriculas",token,200);
                    require(get(prefix+"/cursos",token,200).size()==1,"Course list");get(prefix+"/cursos/"+assignments[i],token,200);
                    get(prefix+"/tareas",token,200);get(prefix+"/cursos/"+assignments[i]+"/tareas",token,200);get(prefix+"/tareas/"+tasks[i],token,200);
                    get(prefix+"/calificaciones",token,200);get(prefix+"/calificaciones/"+grades[i],token,200);
                    require(get(prefix+"/asistencias",token,200).path("resumen").path("total").asInt()==4,"Attendance summary");
                    get(prefix+"/asistencias/"+attendance[i],token,200);get(prefix+"/asistencias?desde=2026-12-31&hasta=2026-01-01",token,400);
                    require(get(prefix+"/comunicados",token,200).size()==2,"Notice audience/validity");get(prefix+"/comunicados/"+notices[i],token,200);
                    String delivery=prefix+"/tareas/"+tasks[i]+"/entrega";
                    if(i==0){submit(delivery,token,"invalido.exe",file,400);submit(delivery,token,"grande.txt",new byte[5*1024*1024+1],413);}
                    long deliveryId=JSON.readTree(submit(delivery,token,"test.txt",file,201).body()).path("id").asLong();
                    ids.computeIfAbsent("entrega_tarea",k->new ArrayList<>()).add(deliveryId);save("ids.json",ids);
                    get(delivery,token,200);require(Arrays.equals(file,request("GET",delivery+"/archivo",token,null,null,200).body()),"Download integrity");
                    submit(delivery,token,"test.txt",file,409);
                    String other="/api/estudiante/matriculas/"+enrollments[1-i];
                    for(String path:List.of(other+"/cursos",other+"/tareas",other+"/tareas/"+tasks[1-i],other+"/calificaciones/"+grades[1-i],other+"/asistencias/"+attendance[1-i],other+"/comunicados/"+notices[1-i],other+"/tareas/"+tasks[1-i]+"/entrega",other+"/tareas/"+tasks[1-i]+"/entrega/archivo",prefix+"/cursos/"+assignments[1-i]))get(path,token,404);
                    submit(other+"/tareas/"+tasks[1-i]+"/entrega",token,"test.txt",file,404);
                }
                submit("/api/estudiante/matriculas/"+enrollments[0]+"/tareas/"+expired+"/entrega",tokens[0],"test.txt",file,409);
                get("/api/estudiante/perfil",null,401);get("/api/estudiante/perfil","invalid",401);
                get("/api/estudiante/perfil",login(run+"_DOC",password),403);
                require(schemaBefore.equals(schema())&&originalBefore.equals(originals()),"Original schema/data changed");
                Files.writeString(dir.resolve("state.txt"),"HTTP_PASSED; SERVER_READY; checks="+checks);
                System.out.println("LIVE_HTTP_PASSED="+checks);System.out.println("LIVE_SERVER_READY=8081");
                // Leave a bounded window for Flutter; stop only this dedicated process by creating stop.txt.
                for(int wait=0;wait<3600&&!Files.exists(dir.resolve("stop.txt"));wait++)Thread.sleep(1000);
                Files.writeString(dir.resolve("state.txt"),"HTTP_PASSED; SERVER_STOPPED; checks="+checks);
            }
        }
    }
}
