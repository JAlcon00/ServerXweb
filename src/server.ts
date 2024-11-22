// server.ts
import express from 'express';
import cors from 'cors';
import DatabaseConnection, {
  getUsuariosCollection,
  getArticulosCollection,
  getPedidosCollection,
  getCategoriasCollection
} from './config/db';

// Importar rutas
import articuloRoutes from './routes/articuloRoutes';
import categoriaRoutes from './routes/categoriaRoutes';
import usuarioRoutes from './routes/usuarioRoutes';
import pedidoRoutes from './routes/pedidoRoutes';


const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Configurar rutas
app.use('/api/articulos', articuloRoutes);
app.use('/api/usuarios', usuarioRoutes);
app.use('/api/pedidos', pedidoRoutes);
app.use('/api/categorias', categoriaRoutes);

// Ruta de prueba de conexión
app.get('/api/test', async (req, res) => {
  try {
    const usuarios = await getUsuariosCollection();
    const count = await usuarios.countDocuments();
    res.json({ message: 'Conexión exitosa', documentCount: count });
  } catch (error) {
    res.status(500).json({ error: 'Error al conectar con la base de datos' });
  }
});

// Función de inicialización
async function inicializarServidor() {
  try {
    // Verificar conexión a la base de datos
    await DatabaseConnection.getInstance();
    
    // Iniciar servidor
    const server = app.listen(PORT, () => {
      console.log(`Servidor corriendo en puerto ${PORT}`);
      console.log('URL del servidor:', `http://localhost:${PORT}`);
    });

    // Manejo de errores global
    app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
      console.error('Error:', err);
      res.status(500).json({ error: 'Error interno del servidor' });
    });

    // Manejo de cierre graceful
    process.on('SIGTERM', async () => {
      console.log('Cerrando servidor...');
      await DatabaseConnection.closeConnection();
      server.close(() => {
        console.log('Servidor cerrado');
        process.exit(0);
      });
    });

    process.on('SIGINT', async () => {
      console.log('Cerrando servidor...');
      await DatabaseConnection.closeConnection();
      server.close(() => {
        console.log('Servidor cerrado');
        process.exit(0);
      });
    });

  } catch (error) {
    console.error('Error al inicializar el servidor:', error);
    process.exit(1);
  }
}

// Iniciar el servidor
inicializarServidor();

export default app;