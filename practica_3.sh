#!/bin/bash
#821342, Cuesta, Jorge, T, 1, B
#875112, Berga, Tahir, T, 1, B

# Número de parámetros correcto
#Comprobamos el numero de parametros
if [ $# -ne 2 ]
then
#Si no es igual a 2 el numero de parametros mensaje de error
echo "Numero incorrecto de parametros" 1>&2
exit 1
else
#Comprobamos que el usuario tenga privilegios de administrador
if [ "$EUID" -ne 0 ]
then
#Si NO tiene privilegios de administrador cortamos la ejecucion
echo "Este script necesita privilegios de administracion" 1>&2
exit 1
else
#Ahora miramos que opcion ha seleccionado, si añadir o borrar
if [ "$1" = "-a" ]
then
#Añadir ususarios
OldIFS=$IFS # Salva el valor de IFS
IFS=, # Cambia a ','
cat "$2" |
while read name passwd fullname resto
do
#comprobamos que ningun campo sea igual a la cadena vacia
if [ ! "$name" -o ! "$passwd" -o ! "$fullname" ]
then
#si alguno coincidia con la cadena vacia se aborta la ejecucion
echo "Campo invalido" 1>&2
exit 1
#comprobamos que no exista ya
elif [ $(cat /etc/passwd | grep "$name:" | wc -l) -ne 0 ]
then
echo "El usuario $(cat /etc/passwd | grep "$name:" |
cut -d':' -f1) ya existe"
else
#si no existia ya y la linea es correcta seguimos
#Creamos los usuarios:
# - Contraseña caduca a los 30 dias
# - El UID sera mayor o igual a 1815
# - El grupo es el mismo al nombre del usuario
# - El direcorio home se iniciara con los fiheros de /etc/skel
#¿Que son todas estas opciones?
# -K: nos sirve para establecer la caducidad de la contraseña y valor minimo del UID
# -U: el grupo se llamara como el usuario
# -m: en el manual pone que para poder usar -k esta tiene que usarse
# -k: sirve para copiar los archivos del skel en el home
# -c: indica cual es el nombre completo del usuario
useradd -K PASS_MAX_DAYS=30 -K UID_MIN=1815 -U -m -k /etc/skel -c "$fullname" "$name"
#asignamos la contraseña la usuario
echo "$name:$passwd" | chpasswd
#desbloqueamos el usuario
usermod -U "$name"
echo "$fullname ha sido creado"
fi
done
IFS=$OldIFS # Recupera el $IFS original
elif [ "$1" = "-s" ]
then
#Borrar usuarios
# Crea /extra/backup si no existe
if [ ! -d "/extra" ]
then
mkdir /extra/
fi
if [ ! -d "/extra/backup" ]
then
mkdir /extra/backup/
fi
OldIFS=$IFS # Salva el valor de IFS
IFS=, # Cambia a ','
cat "$2" |
while read name resto
do
#comprobamos que ningun campo sea igual a la cadena vacia
if [ ! "$name" ]
then
#si alguno coincidia con la cadena vacia se aborta la ejecucion
echo "Campo invalido" 1>&2
exit 1
#comprobamos que exista el usuario y no sea el root
elif [ $(cat /etc/passwd | grep "$name:" | wc -l) -ne 0 -a "$name" != "root" ]
then
#en caso de que no exista el usuario no hacemos nada
#antes de borrarlo hay que crear un backup de su home
if tar cfP "/extra/backup/$name.tar" "$(cat /etc/passwd | grep "$name:" | cut -d':' -f6)"
then
#se borra el usuario y su home
userdel -r "$name" 2>/dev/null
fi
fi
done
IFS=$OldIFS # Recupera el $IFS original
else
#No es ninguna de las opciones
echo "Opcion invalida" 1>&2
exit 1
fi
fi
fi
