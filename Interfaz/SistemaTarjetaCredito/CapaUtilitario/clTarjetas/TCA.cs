using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CapaUtilitario.clTarjetas
{
    public class TCA
    {

        public int ID { get; set; }
        public string NumeroTarjeta { get; set; }
        public DateTime Fecha { get; set; }
        public int CantidadOperacionesATM { get; set; }
        public int CantidadOperacioneVentanilla { get; set; }
        public int CantidadCompras { get; set; }
        public decimal SumaCompras { get; set; }
        public int CantidadRetiros { get; set; }
        public decimal SumaRetiros { get; set; }
        public decimal SumaCreditos { get; set; }
        public decimal SumaDebitos { get; set; }

    }
}
