import { Router} from "express";
import { 
    crearArticulo, 
    obtenerArticulos, 
    actualizarArticulo,
    obtenerArticuloById,
    eliminarArticulo,
    buscarArticulosPorCategoria,
    buscarArticulosPorNombre 
} from "../controllers/articuloController";

const router = Router();

// Rutas específicas primero
router.post("/", crearArticulo);
router.get("/", obtenerArticulos);
router.get("/:id", obtenerArticuloById);
router.put("/:id", actualizarArticulo);
router.delete("/:id", eliminarArticulo);
router.get("/buscar", buscarArticulosPorNombre);
router.get("/categoria/:categoriaId", buscarArticulosPorCategoria);

//By Jesus Almanza

export default router;