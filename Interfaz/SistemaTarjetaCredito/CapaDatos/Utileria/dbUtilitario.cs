using CapaUtilitario.clTarjetas;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;


namespace CapaDatos.Utilitario
{
    public class dbUtilitario
    {


        public int Login(SqlConnectionStringBuilder connectionString, string usuario, string pass)
        {
            int resultCode = 505;
            string command = "[dbo].[SP_Login]";

            using (SqlConnection conn = new SqlConnection(connectionString.ConnectionString))
            {
                conn.Open();
                using (SqlCommand comando = new SqlCommand(command, conn))
                {
                    comando.CommandType = System.Data.CommandType.StoredProcedure;

                    // Agregar parámetros de entrada
                    comando.Parameters.AddWithValue("@inUsuario", usuario);
                    comando.Parameters.AddWithValue("@inClave", pass);

                    // Agregar el parámetro de salida
                    SqlParameter outResultCodeParam = new SqlParameter("@outResultCode", System.Data.SqlDbType.Int)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    comando.Parameters.Add(outResultCodeParam);

                    // Ejecutar el procedimiento almacenado
                    comando.ExecuteNonQuery();

                    // Obtener el valor del parámetro de salida
                    resultCode = (int)outResultCodeParam.Value;
                }
                conn.Close();
            }

            return resultCode;
        }







    }






}
