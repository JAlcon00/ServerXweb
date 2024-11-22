import { Router} from "express";

// Importar controladores
import{
    crearCategoria,
    obtenerCategorias,
    obtenerCategoriaById,
    actualizarCategoria,
    eliminarCategoria
} from "../controllers/categoriaController";


const router = Router();

// Definir rutas
router.post('/', crearCategoria);
router.get('/', obtenerCategorias);
router.get('/:id', obtenerCategoriaById);
router.put('/:id', actualizarCategoria);
router.delete('/:id', eliminarCategoria);

export default router;
