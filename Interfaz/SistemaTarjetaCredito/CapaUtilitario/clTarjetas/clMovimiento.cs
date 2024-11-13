using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CapaUtilitario.clTarjetas
{
    public class clMovimiento
    {
        public string Nombre { get; set; }
        public DateTime Fecha { get; set; }
        public decimal Monto { get; set; }
        public decimal NuevoSaldo { get; set; }
        public string Referencia { get; set; }
        public string Descripcion { get; set; }
        public string TF { get; set; }

    }
}
