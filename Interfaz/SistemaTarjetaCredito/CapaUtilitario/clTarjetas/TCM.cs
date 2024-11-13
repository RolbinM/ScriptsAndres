using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CapaUtilitario.clTarjetas
{
    public class TCM
    {
        public string NumeroTarjeta { get; set; }
        public DateTime Fecha { get; set; }
        public decimal PagoMinimo { get; set; }
        public decimal PagoContado { get; set; }
        public decimal InteresesCorrientes { get; set; }
        public decimal InteresMoratorios { get; set; }
        public int CantidadOperacionesATM { get; set; }
        public int CantidadOperacioneVentanilla { get; set; }
    }
}
