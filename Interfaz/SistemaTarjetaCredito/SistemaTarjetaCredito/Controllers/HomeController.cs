using Microsoft.AspNetCore.Mvc;
using SistemaTarjetaCredito.Models;
using System.Diagnostics;
using Microsoft.Data.SqlClient;
using CapaDatos;
using CapaDatos.Tarjetas;
using CapaDatos.Utilitario;


namespace SistemaTarjetaCredito.Controllers
{
    public class HomeController : Controller
    {
        /*Manejo de Session*/
        private readonly IHttpContextAccessor _contextAccessor;
        public IConfiguration configuration;

        /* Objeto de Conexión */
        SqlConnectionStringBuilder conexionString = new SqlConnectionStringBuilder();
        /* Instancias de la CapaDatos */
        dbConexion dbConexion = new dbConexion();
        dbTarjeta dbTarjeta = new dbTarjeta();
        dbUtilitario dbUtilitario = new dbUtilitario();



        public HomeController(IHttpContextAccessor contextAccessor, IConfiguration _configuration)
        {
            _contextAccessor = contextAccessor;
            configuration = _configuration;

            conexionString = dbConexion.obtenerConexion("LRivelP", "BD1_TP3", "sa", "sa");
        }

        public IActionResult Index()
        {
            return View();
        }

        public IActionResult ListaTarjetasAdmin()
        {

            var Tarjetas = dbTarjeta.ListarTarjetasAdmin(conexionString);
            return View(Tarjetas);
        }

        public IActionResult ListaTarjetas(string user)
        {

            string TipoUsuario = _contextAccessor.HttpContext.Session.GetString("Tipo");
            string usuario =  _contextAccessor.HttpContext.Session.GetString("Usuario");

            if (TipoUsuario == "Administrador" && user == null)
            {
                return RedirectToAction("ListaTarjetasAdmin");
            }

            
            

            if (user != null && user != "") 
            {
                usuario = user;
            }
            
    
            var Tarjetas = dbTarjeta.ListarTarjetas(conexionString, usuario);
            return View(Tarjetas);
        }

        public IActionResult TCA(string codigo)
        {
            var VTCA = dbTarjeta.ListarTCA(conexionString, codigo);
            ViewBag.Codigo = codigo;
            return View(VTCA);
        }

        public IActionResult TCM(string codigo)
        {
             var VTCM = dbTarjeta.ListarTCM(conexionString, codigo);
            ViewBag.Codigo = codigo;
            return View(VTCM);
        }

        public IActionResult Movimiento(string codigoTF, string codigoEstado, string Tipo)
        {
            var VMovimiento = dbTarjeta.ListarMovimientos(conexionString, codigoTF, codigoEstado, Tipo);
            return View(VMovimiento);
        }

        public IActionResult CerrarSesion()
        {
            _contextAccessor.HttpContext.Session.SetString("Usuario", "");
            _contextAccessor.HttpContext.Session.SetString("Esquema", "");
            _contextAccessor.HttpContext.Session.SetString("Tipo", "");


            return RedirectToAction("Index", "Home");
        }

        public int login(string inUsuario, string inContrasena)
        {
            int resultado = dbUtilitario.Login(conexionString, inUsuario, inContrasena);

            if (resultado != 505)
            {
                _contextAccessor.HttpContext.Session.SetString("Usuario", inUsuario);

                if(resultado == 1)
                {
                    _contextAccessor.HttpContext.Session.SetString("Tipo", "Administrador");
                }
            }

            

            
            return resultado;
        }
    }
}
