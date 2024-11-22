import { Router } from "express";
import { 
    crearUsuario, 
    obtenerUsuarios, 
    obtenerUsuariobyId,
    actualizarUsuario,
    eliminarUsuario,
    loginUsuario,
    cambiarPassword,
    buscarUsuariosPorRol,
    buscarUsuariosPorNombre
} from "../controllers/usuarioController";
import { loginLimiter } from "../middleware/rateLimiter";

const router = Router();

// Rutas públicas
router.post("/", crearUsuario);
router.get("/", obtenerUsuarios);

// Rutas de búsqueda
router.get("/buscar", buscarUsuariosPorNombre);
router.get("/rol/:rol", buscarUsuariosPorRol);

// Ruta para obtener usuario por ID (debe ir después de las rutas anteriores)
router.get("/:id", obtenerUsuariobyId);

// Rutas de autenticación
router.post("/login", loginLimiter, loginUsuario);

// Rutas privadas (requieren autenticación)
router.put("/:id", actualizarUsuario);
router.delete("/:id", eliminarUsuario);
router.put("/:id/password", cambiarPassword);

export default router;