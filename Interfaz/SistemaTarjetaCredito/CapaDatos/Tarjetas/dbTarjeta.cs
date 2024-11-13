using CapaUtilitario.clTarjetas;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;


namespace CapaDatos.Tarjetas
{
    public class dbTarjeta
    {


        public List<Tarjeta> ListarTarjetasAdmin(SqlConnectionStringBuilder connectionString)
        {
            List<Tarjeta> listaOrdenes = new List<Tarjeta>();
            string command = "dbo.SP_ListadoTFs_Admin";

            using (SqlConnection conn = new SqlConnection(connectionString.ConnectionString))
            {
                conn.Open();
                using (SqlCommand comando = new SqlCommand(command, conn))
                {
                    comando.CommandType = System.Data.CommandType.StoredProcedure;


                    SqlParameter outResultCode = new SqlParameter("@outResultCode", System.Data.SqlDbType.VarChar, 50)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    comando.Parameters.Add(outResultCode);

                    using (SqlDataReader reader = comando.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            listaOrdenes.Add(new Tarjeta
                            {
                                Usuario = reader["Usuario"].ToString(),
                                NumeroTarjeta = reader["CodigoTF"].ToString(),
                                FechaEmision = Convert.ToDateTime(reader["FechaCreacion"]),
                                FechaVencimiento = Convert.ToDateTime(reader["FechaVencimiento"]),
                                Estado = reader["Activa"].ToString(),
                                TipoCuenta = reader["TipoCuenta"].ToString()
                            });
                        }
                    }

                    // Cerrar el DataReader antes de leer el valor del parámetro OUTPUT
                    comando.ExecuteNonQuery();
                    string resultCode = outResultCode.Value.ToString();
                    if (resultCode != "0")
                    {
                        // Maneja el código de error según sea necesario
                        listaOrdenes.Add(new Tarjeta
                        {
                            codigoError = resultCode

                        });

                    }
                }
                conn.Close();
            }

            return listaOrdenes;
        }

        public List<Tarjeta> ListarTarjetas(SqlConnectionStringBuilder connectionString, string usuario)
        {
            List<Tarjeta> listaOrdenes = new List<Tarjeta>();
            string command = "dbo.SP_ListadoTFs";

            using (SqlConnection conn = new SqlConnection(connectionString.ConnectionString))
            {
                conn.Open();
                using (SqlCommand comando = new SqlCommand(command, conn))
                {
                    comando.CommandType = System.Data.CommandType.StoredProcedure;
                    comando.Parameters.AddWithValue("@inUsuario", usuario);

              
                    SqlParameter outResultCode = new SqlParameter("@outResultCode", System.Data.SqlDbType.VarChar, 50)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    comando.Parameters.Add(outResultCode);

                    using (SqlDataReader reader = comando.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            listaOrdenes.Add(new Tarjeta
                            {
                                NumeroTarjeta = reader["CodigoTF"].ToString(),
                                FechaEmision = Convert.ToDateTime(reader["FechaCreacion"]),
                                FechaVencimiento = Convert.ToDateTime(reader["FechaVencimiento"]),
                                Estado = reader["Activa"].ToString(),
                                TipoCuenta = reader["TipoCuenta"].ToString()
                            });
                        }
                    }

                    // Cerrar el DataReader antes de leer el valor del parámetro OUTPUT
                    comando.ExecuteNonQuery();
                    string resultCode = outResultCode.Value.ToString();
                    if (resultCode != "0")
                    {
                        // Maneja el código de error según sea necesario
                        listaOrdenes.Add(new Tarjeta
                        {
                            codigoError = resultCode

                        });
                        
                    }
                }
                conn.Close();
            }

            return listaOrdenes;
        }



        public List<TCM> ListarTCM(SqlConnectionStringBuilder connectionString, string codigo)
        {
            List<TCM> listaOrdenes = new List<TCM>();

            string command = "dbo.SP_ListadoEstadosCuentaTCM";

            using (SqlConnection conn = new SqlConnection(connectionString.ConnectionString))
            {
                conn.Open();
                using (SqlCommand comando = new SqlCommand(command, conn))
                {
                    comando.CommandType = System.Data.CommandType.StoredProcedure;
                    comando.Parameters.AddWithValue("@inCodigoTF", codigo);

                    SqlParameter outResultCode = new SqlParameter("@outResultCode", System.Data.SqlDbType.VarChar, 50)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    comando.Parameters.Add(outResultCode);

                    using (SqlDataReader reader = comando.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            listaOrdenes.Add(new TCM
                            {
                                NumeroTarjeta = reader["NumeroTarjeta"].ToString(),
                                Fecha = Convert.ToDateTime(reader["FechaCorte"]),
                                PagoMinimo = Convert.ToDecimal(reader["PagoMinimo"]),
                                PagoContado = Convert.ToDecimal(reader["PagoContado"]),
                                InteresesCorrientes = Convert.ToDecimal(reader["InteresesCorrientes"]),
                                InteresMoratorios = Convert.ToDecimal(reader["InteresesMoratorios"]),
                                CantidadOperacionesATM = Convert.ToInt32(reader["CantidadOperacionesATM"]),
                                CantidadOperacioneVentanilla = Convert.ToInt32(reader["CantidadOperacionesVentanilla"])


                            });
                        }
                    }
                }
                conn.Close();
            }

            return listaOrdenes;

        }

        public List<TCA> ListarTCA(SqlConnectionStringBuilder connectionString, string codigo)
        {
            List<TCA> listaOrdenes = new List<TCA>();

            string command = "dbo.SP_ListadoEstadosCuentaTCA";

            using (SqlConnection conn = new SqlConnection(connectionString.ConnectionString))
            {
                conn.Open();
                using (SqlCommand comando = new SqlCommand(command, conn))
                {
                    comando.CommandType = System.Data.CommandType.StoredProcedure;
                    comando.Parameters.AddWithValue("@inCodigoTF", codigo);

                    SqlParameter outResultCode = new SqlParameter("@outResultCode", System.Data.SqlDbType.VarChar, 50)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    comando.Parameters.Add(outResultCode);

                    using (SqlDataReader reader = comando.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            listaOrdenes.Add(new TCA
                            {
                                ID = Convert.ToInt32(reader["id"]),
                                NumeroTarjeta = reader["idTCA"].ToString(),
                                Fecha = Convert.ToDateTime(reader["FechaCorte"]),
                                CantidadOperacionesATM = Convert.ToInt32(reader["OperacionesATM"]),
                                CantidadOperacioneVentanilla = Convert.ToInt32(reader["OperacionesVentanilla"]),
                                CantidadCompras = Convert.ToInt32(reader["CantidadCompras"]),
                                SumaCompras = Convert.ToDecimal(reader["SumaCompras"]),
                                CantidadRetiros = Convert.ToInt32(reader["CantidadRetiros"]),
                                SumaRetiros = Convert.ToDecimal(reader["SumaRetiros"]),
                                SumaCreditos = Convert.ToDecimal(reader["SumaCreditos"]),
                                SumaDebitos = Convert.ToDecimal(reader["SumaDebitos"])
                            });
                        }
                    }
                }
                conn.Close();
            }

            return listaOrdenes;

        }


        public List<clMovimiento> ListarMovimientos(SqlConnectionStringBuilder connectionString, string codigoTF, string codigoEstado, string Tipo)
        {
            List<clMovimiento> listaOrdenes = new List<clMovimiento>();

            string command = "dbo.SP_ListadoDetalleEC";

            using (SqlConnection conn = new SqlConnection(connectionString.ConnectionString))
            {
                conn.Open();
                using (SqlCommand comando = new SqlCommand(command, conn))
                {
                    comando.CommandType = System.Data.CommandType.StoredProcedure;
                    comando.Parameters.AddWithValue("@inCodigoTF", codigoTF);

                    if (Tipo == "TCM")
                    {
                        comando.Parameters.AddWithValue("@inIdEstadoCuenta", codigoEstado);
                    }
                    else
                    {
                        comando.Parameters.AddWithValue("@inIdSubEstadoCuenta", codigoEstado);
                    }

                    SqlParameter outResultCode = new SqlParameter("@outResultCode", System.Data.SqlDbType.VarChar, 50)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    comando.Parameters.Add(outResultCode);

                    using (SqlDataReader reader = comando.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            listaOrdenes.Add(new clMovimiento
                            {
                                Nombre = reader["Nombre"].ToString(),
                                Fecha = Convert.ToDateTime(reader["Fecha"]),
                                Monto = Convert.ToDecimal(reader["Monto"]),
                                NuevoSaldo = Convert.ToDecimal(reader["NuevoSaldo"]),
                                Referencia = reader["Referencia"].ToString(),
                                Descripcion = reader["Descripcion"].ToString()

                            });
                        }
                    }
                }
                conn.Close();
            }

            return listaOrdenes;

        }


    }






}
