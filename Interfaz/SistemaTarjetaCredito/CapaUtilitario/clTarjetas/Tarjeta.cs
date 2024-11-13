using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CapaUtilitario.clTarjetas
{
    public class Tarjeta
    {
        public string Usuario { get; set; }
        public string NumeroTarjeta { get; set; }
        public string Estado { get; set; }
        public string TipoCuenta { get; set; }
        public DateTime FechaVencimiento { get; set; }
        public DateTime FechaEmision { get; set; }
        public string? codigoError { get; set; }

    }
}
                    